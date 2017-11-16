import Foundation

protocol Router {
    associatedtype Calculation: Hashable
    associatedtype Answer
    
    func routeToDifficulty(callBack: @escaping (Difficulty) -> Void)
    func routeTo(calculation: Calculation, difficulty: Difficulty, callBack: @escaping (Answer) -> Void)
    func routeTo(result: [Calculation: Answer]?)

}

enum Difficulty {
    case easy
    case medium
    case hard
}

class Flow<R: Router, Calculation, Answer> where Calculation == R.Calculation, Answer == R.Answer {
    private let router: R
    private let calculations: [Difficulty: [Calculation]]
    private var answers: [Calculation: Answer] = [:]
    private var difficulty: Difficulty?
    
    init(_ router: R, _ calculations: [Difficulty: [Calculation]]) {
        self.router = router
        self.calculations = calculations
    }
    
    func selectDifficulty() {
        router.routeToDifficulty { [weak self] difficulty in
            self?.difficulty = difficulty
        }
    }
    
    func start() {
        guard let difficulty = difficulty else {
            fatalError("Difficulty is not set")
        }
        
        if let calculations = calculations[difficulty], let firstCalculation = calculations.first {
            router.routeTo(calculation: firstCalculation, difficulty: difficulty, callBack: callback(for: firstCalculation))
        } else {
            router.routeTo(result: nil)
        }
    }
    
    private func callback(for calculation: Calculation) -> (Answer) -> Void {
        return { [weak self] in
            self?.handleCallback(calculation, $0)
        }
    }
    
    private func handleCallback(_ calculation: Calculation, _ answer: Answer) {
        guard let difficulty = difficulty else {
            fatalError("Difficulty is not set")
        }
        
        guard let calculations = calculations[difficulty], let currentIndex = calculations.index(of: calculation) else {
            fatalError("Didn't find calculation in array")
        }
        answers[calculation] = answer
        let nextIndex = currentIndex + 1
        if nextIndex < calculations.count {
            router.routeTo(calculation: calculations[nextIndex], difficulty: difficulty, callBack: callback(for: calculations[nextIndex]))
        } else {
            router.routeTo(result: answers)
        }
    }
}
