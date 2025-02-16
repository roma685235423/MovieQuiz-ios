import UIKit





final class MovieQuizViewController: UIViewController, MovieQuizViewControllerProtocol {
    
    //MARK: - Properties
    // Аутлеты для текста, счётчика, изображения и кнопок
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    // Презентер
    private var presenter: MovieQuizPresenter!
    
    enum CodingKeys: String, CodingKey {
        case id, title, year, image, runtimeMins, directors, actorList
        case releaseDate = "release_date"
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter = MovieQuizPresenter(viewController: self)
        
        imageView.layer.cornerRadius = 20
        
    }
    
    //MARK: - Actions
    // Действия по нажатию кнопки "Нет"
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        presenter.noButtonClicked()
    }
    
    // Действия по нажатию кнопки "Да"
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        presenter.yesButtonClicked()
    }
    
    //MARK: - Functions
    // Функция для передачи в вью модель необходимых данных
    func show(quiz step: QuizStepViewModel) {
        self.imageView.image = step.image
        self.textLabel.text = step.question
        self.counterLabel.text = step.questionNumber
    }
    
    // Функция для вызова алерта с результатами раунда
    func show(quiz result: QuizResultsViewModel) {
        let alertModel = AlertModel(
            title: result.title,
            message: result.text,
            buttonText: result.buttonText
        ) { [weak self] in
            guard let self = self else { return }
            // restart
            self.presenter.restartGame()
            // заново показываем первый вопрос
        }
        let  alertPresenter = AlertPresenter()
        alertPresenter.show(in: self, model: alertModel)
    }
    
    // Функция для отображения рамки с цветовой индикацией правильности ответа
    func highlightImageBorder(isCorrectAnswer: Bool){
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrectAnswer ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
    }
    // Функция для скрытия рамки
    func hideImageBoarder () {
        imageView.layer.borderWidth = 0
    }
    // Функция блокировки переключения активности кнопок. Используется в showAnswerResult
    func toggleIsEnablebButtons(){
        noButton.isEnabled.toggle()
        yesButton.isEnabled.toggle()
    }
    
    // Функция для отбражения индикатора загрузки изображения из сети
    func showLoadingIndicator() {
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
    }
    
    // Функция скрытия индикатора загрузки изображения из сети
    func hideLoadingIndicator(){
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    // Функция отображениия ошибки загрузки из сети
    func showNetworkError (error: Error) {
//        func showNetworkError (message: String) {
        showLoadingIndicator()
        print(error)
        var stringErr = error.localizedDescription
        stringErr = stringErr.uppercased()
        let unHappyResultModel = AlertModel(
            title: "Ошибка",
            message: stringErr ,
            buttonText: "Попробовать ещё раз"
        ) { [weak self] in
            guard let self = self else {return}
            print (error)
            self.presenter.restartGame()
        }
        let alertPresenter = AlertPresenter()
        alertPresenter.show(in: self, model: unHappyResultModel)
    }
}
