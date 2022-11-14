import UIKit





final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {

    //MARK: - Properties
    // Аутлеты для текста, счётчика, изображения и кнопок
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    // Переменная индекса текущего вопроса в MovieQuizViewController
    //private var currentQuestionIndex: Int = 0
    // Переменная для подсчёта колличества верных ответов
    private var correctAnswers: Int = 0
    // Общее колличество вопросов
    //private let questionsAmount: Int = 10
    // Экземпляр фабрики вопросов
    var questionFactory: QuestionFactoryProtocol?
    // Текущий вопрос, который видит пользователь
    private var currentQuestion: QuizQuestion?
    // Экземпляр AlertPresenter для отображения Алерта
    private let alertPresenter = AlertPresenter()
    //
    private var statisticService: StatisticServiceImplementation = .init()
    //
    
    private let presenter = MovieQuizPresenter()
    enum CodingKeys: String, CodingKey {
       case id, title, year, image, runtimeMins, directors, actorList
       case releaseDate = "release_date"
    }
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        statisticService = StatisticServiceImplementation()
        questionFactory?.loadData()
        showLoadingIndicator()
        
    }
    //MARK: - QuestionFactoryDelegate
    // Функция для запроса следующего вопроса
    func didReciveNextQuestion (question: QuizQuestion?) {
        guard let question = question else { return }
        currentQuestion = question
        let viewModel = presenter.convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    //MARK: - Actions
    // Действие по нажатию кнопки "Нет"
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = false
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = true
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    //MARK: - Helpers
    // Функция для создания первой вью модели
    private func startGame(question: [QuizQuestion]?){
        guard let questions = question else{
            return
        }
        let viewModel = presenter.convert(model: questions[0])
        show(quiz: viewModel)
    }
    
    // Функция для передачи в вью модель необходимых данных
    private func show(quiz step: QuizStepViewModel) {
        self.imageView.image = step.image
        self.textLabel.text = step.question
        self.counterLabel.text = step.questionNumber
    }
    
    // Функция для вызова алерта с результатами раунда
    private func show(quiz result: QuizResultsViewModel) {
        let alertModel = AlertModel(
            title: result.title,
            message: result.text,
            buttonText: result.buttonText
        ) { [weak self] in
            guard let self = self else { return }
           // restart
            self.presenter.resetQuestionIndex()
            self.correctAnswers = 0
            // заново показываем первый вопрос
            self.questionFactory?.requestNextQuestion()
        }
        alertPresenter.show(in: self, model: alertModel)
    }

    // Функция для отображения рамки с цветовой индикацией правильности ответа и блокировки кнопок на времяпоказа рамки с последующей разблокировкой и убиранием рамки
    private func showAnswerResult(isCorrect: Bool){
        if isCorrect {
            correctAnswers += 1
        }
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [ weak self ] in
            guard let self = self else { return }
                self.showNextQuestionOrResults()
                self.imageView.layer.borderWidth = 0
                self.toggleIsEnablebButtons()
            }
        toggleIsEnablebButtons()
    }
    
    // Функция выбора действия: показ результата раунда, если вопрос последний или следующего вопроса
    private func showNextQuestionOrResults() {
        if presenter.isLastQuestion() {
            statisticService.gamesCount += 1
            statisticService.store(correct: correctAnswers, total: presenter.questionsAmount)
            let bestGameText = "\(statisticService.bestGame.correct)/\(statisticService.bestGame.total) (\(statisticService.bestGame.date.dateTimeString))"
            let text = "Ваш результат: \(correctAnswers)/\(presenter.questionsAmount)\nКолличество сыгранных квизов: \(statisticService.gamesCount)\nРекорд: \(bestGameText)\nСредняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%"
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: text,
                buttonText: "Сыграть ещё раз")
            self.show(quiz: viewModel)
        } else {
            presenter.switchToNextQuestion()
            questionFactory?.requestNextQuestion()
        }
    }
    // Функция для действий при удачном походе в сеть
    func didloadDataFromServer () {
        hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }

    // Функция для действий при неудачном походе в сеть
    func didFailToLoadData(with error: Error) {
        showLoadingIndicator()
        showNetworkError(error: error)
    }
    
    // Функция блокировки переключения активности кнопок. Используется в showAnswerResult
    func toggleIsEnablebButtons(){
        noButton.isEnabled.toggle()
        yesButton.isEnabled.toggle()
    }
    
    // Функция для отбражения индикатора загрузки изображения из сети
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    // Функция скрытия индикатора загрузки изображения из сети
    private func hideLoadingIndicator(){
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
    }
    
    // Функция отображениия ошибки загрузки из сети
    private func showNetworkError (error: Error) {
        showLoadingIndicator()
        let unHappyResultModel = AlertModel(
            title: "Ошибка",
            message: error.localizedDescription,
            buttonText: "Попробовать ещё раз"
        ) { [weak self] in
            guard let self = self else {return}
            self.hideLoadingIndicator()
            self.questionFactory?.loadData()
        }
        let alertPresenter = AlertPresenter()
        alertPresenter.show(in: self, model: unHappyResultModel)
    }

}
