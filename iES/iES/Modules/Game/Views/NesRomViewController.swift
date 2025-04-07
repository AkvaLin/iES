//
//  NesRomViewController.swift
//  nes-emu-ios
//
//  Created by Tom Salvo on 6/8/20.
//  Copyright © 2020 Tom Salvo.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit
import GameController
import CoreData
import SwiftData

final class NesRomViewController: GCEventViewController
{
    // MARK: - Constants
    private static let defaultFrameQueueSize: Int = 3
    private static let analogDeadZoneLeftRight: Float = 0.23
    private static let analogDeadZoneUpDown: Float = 0.3
    
    // MARK: - UI
    private var screen: NESScreenView = {
        guard let bounds = UIScreen.current?.bounds else { fatalError("UIScreen.current?.bounds is nil") }
        let height = bounds.height
        let width = height / 14 * 16
        let isMetalEnabled = UserDefaults.standard.bool(forKey: Settings.Keys.metalFxEnabled)
        let frame = CGRect(x: 0, y: 0, width: width, height: height)
        #if !targetEnvironment(simulator)
        guard
            let screen = (isMetalEnabled ? NESScreenViewMetalFX(frame: frame) : NESScreenViewTraditional(frame: frame))
                as? NESScreenView
        else { fatalError("type cast failed") }
        #else
        let screen = NESScreenViewTraditional(frame: frame)
        #endif
        return screen
    }()
    private var aButton: UIButton = {
        guard let bounds = UIScreen.current?.bounds else { fatalError("UIScreen.current?.bounds is nil") }
        let width = bounds.width / 13
        let button = UIButton(
            frame: CGRect(
                x: bounds.width - width * 2,
                y: bounds.height - width * 1.5,
                width: width,
                height: width
            )
        )
        button.configuration = .borderedTinted()
        button.configuration?.title = "A"
        button.configuration?.baseBackgroundColor = .systemRed
        button.configuration?.baseForegroundColor = .systemRed
        button.configuration?.cornerStyle = .capsule
        return button
    }()
    private var bButton: UIButton = {
        guard let bounds = UIScreen.current?.bounds else { fatalError("UIScreen.current?.bounds is nil") }
        let width = bounds.width / 13
        let button = UIButton(
            frame: CGRect(
                x: bounds.width - width * 2,
                y: bounds.height - width * 3.5,
                width: width,
                height: width
            )
        )
        button.configuration = .borderedTinted()
        button.configuration?.title = "B"
        button.configuration?.baseBackgroundColor = .systemRed
        button.configuration?.baseForegroundColor = .systemRed
        button.configuration?.cornerStyle = .capsule
        return button
    }()
    private var upButton: UIButton = {
        guard let bounds = UIScreen.current?.bounds else { fatalError("UIScreen.current?.bounds is nil") }
        let width = bounds.width / 13
        let button = UIButton(
            frame: CGRect(
                x: width * 2,
                y: bounds.height - width * 3.5,
                width: width,
                height: width
            )
        )
        button.configuration = .borderedTinted()
        button.configuration?.image = UIImage(systemName: "arrowshape.up.fill")
        button.configuration?.baseBackgroundColor = .darkGray
        button.configuration?.baseForegroundColor = .lightGray
        return button
    }()
    private var downButton: UIButton = {
        guard let bounds = UIScreen.current?.bounds else { fatalError("UIScreen.current?.bounds is nil") }
        let width = bounds.width / 13
        let button = UIButton(
            frame: CGRect(
                x: width * 2,
                y: bounds.height - width * 1.5,
                width: width,
                height: width
            )
        )
        button.configuration = .borderedTinted()
        button.configuration?.image = UIImage(systemName: "arrowshape.down.fill")
        button.configuration?.baseBackgroundColor = .darkGray
        button.configuration?.baseForegroundColor = .lightGray
        return button
    }()
    private var leftButton: UIButton = {
        guard let bounds = UIScreen.current?.bounds else { fatalError("UIScreen.current?.bounds is nil") }
        let width = bounds.width / 13
        let button = UIButton(
            frame: CGRect(
                x: width,
                y: bounds.height - width * 2.5,
                width: width,
                height: width
            )
        )
        button.configuration = .borderedTinted()
        button.configuration?.image = UIImage(systemName: "arrowshape.left.fill")
        button.configuration?.baseBackgroundColor = .darkGray
        button.configuration?.baseForegroundColor = .lightGray
        return button
    }()
    private var rightButton: UIButton = {
        guard let bounds = UIScreen.current?.bounds else { fatalError("UIScreen.current?.bounds is nil") }
        let width = bounds.width / 13
        let button = UIButton(
            frame: CGRect(
                x: width * 3,
                y: bounds.height - width * 2.5,
                width: width,
                height: width
            )
        )
        button.configuration = .borderedTinted()
        button.configuration?.image = UIImage(systemName: "arrowshape.right.fill")
        button.configuration?.baseBackgroundColor = .darkGray
        button.configuration?.baseForegroundColor = .lightGray
        return button
    }()
    private var selectButton: UIButton = {
        guard let bounds = UIScreen.current?.bounds else { fatalError("UIScreen.current?.bounds is nil") }
        let width = bounds.width / 13
        let button = UIButton(
            frame: CGRect(
                x: width * 2,
                y: width * 0.5,
                width: width,
                height: width / 2
            )
        )
        button.configuration = .borderedTinted()
        button.configuration?.title = "SELECT"
        
        button.configuration?.baseBackgroundColor = .darkGray
        button.configuration?.baseForegroundColor = .lightGray
        return button
    }()
    private var startButton: UIButton = {
        guard let bounds = UIScreen.current?.bounds else { fatalError("UIScreen.current?.bounds is nil") }
        let width = bounds.width / 13
        let button = UIButton(
            frame: CGRect(
                x: bounds.width - width * 2,
                y: width * 0.5,
                width: width,
                height: width / 2
            )
        )
        button.configuration = .borderedTinted()
        button.configuration?.title = "START"
        button.configuration?.baseBackgroundColor = .darkGray
        button.configuration?.baseForegroundColor = .lightGray
        return button
    }()
    
    // MARK: - Private Variables
    private weak var dismissBarButtonItem: UIBarButtonItem?
    private weak var resetBarButtonItem: UIBarButtonItem?
    private weak var saveStateBarButtonItem: UIBarButtonItem?
    private weak var controller1BarButtonItem: UIBarButtonItem?
    private weak var controller2BarButtonItem: UIBarButtonItem?
    
    private var consoleFrameQueueSize: Int = NesRomViewController.defaultFrameQueueSize
    private var consoleFramesQueued: Int = 0
    var cartridge: Cartridge? {
        didSet {
            guard let safeCartridge = self.cartridge else { return }
            let sampleRate: SampleRate = SampleRate.init(rawValue: UserDefaults.standard.integer(forKey: Settings.Keys.sampleRate)) ?? Settings.DefaultValues.defaultSampleRate
            let audioEnabled: Bool = UserDefaults.standard.bool(forKey: Settings.Keys.audioEnabled)
            let audioFiltersEnabled: Bool = UserDefaults.standard.bool(forKey: Settings.Keys.audioFiltersEnabled)
            self.consoleQueue.async { [weak self] in
                let state: EmulatorState? =
                if let stateDTO = self?.gameModel?.state {
                    EmulatorState(from: stateDTO)
                } else {
                    nil
                }
                self?.console = Emulator(withCartridge: safeCartridge, sampleRate: sampleRate, audioFiltersEnabled: audioFiltersEnabled, state: state)
                self?.console?.set(audioEngineDelegate: audioEnabled ? self?.audioEngine : nil)
                if self?.gameModel?.state == nil {
                    self?.console?.reset()
                }
            }
        }
    }
    private let consoleQueue: DispatchQueue = DispatchQueue(label: "ConsoleQueue", qos: .userInteractive)
    private var hasSuspended: Bool = false
    
    private var console: Emulator?
    private var displayLink: CADisplayLink?
    private let audioEngine: AudioEngine = AudioEngine()
    private var gameModel: GameModel?
    private var profile: ProfileModel?
    private var timer: Timer?
    private var modelContext: ModelContext?
    
    func setup(cartridge: Cartridge?, gameModel: GameModel?, profile: ProfileModel, modelContext: ModelContext) {
        self.gameModel = gameModel
        self.cartridge = cartridge
        self.profile = profile
        self.modelContext = modelContext
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
            self.updateTimePlayed()
        })
    }
    
    // MARK: - Appearance
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    
    // MARK: - UIResponder
    override var canBecomeFirstResponder: Bool { true }
    
    // MARK: - UIViewController Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(appResignedActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appBecameActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        self.controllerUserInteractionEnabled = false
        self.consoleFrameQueueSize = NesRomViewController.defaultFrameQueueSize

        view.backgroundColor = .black
        
        screen.center = view.center
        view.addSubview(screen)
        setupControlButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.becomeFirstResponder()
        UIApplication.shared.isIdleTimerDisabled = true
        self.createDisplayLink()
        if let gameModel, let modelContext {
            GamesService.updateLastTimePlayed(for: gameModel, context: modelContext)
            if let profile {
                ProfileService.updateLastActivity(profile: profile, lastActivity: gameModel.title, context: modelContext)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        screen.stopUpdating = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.destroyDisplayLink()
        self.resignFirstResponder()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.GCControllerDidConnect, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.GCControllerDidDisconnect, object: nil)
        UIApplication.shared.isIdleTimerDisabled = false
        if let gameModel, gameModel.isAutoSaveEnabled, let newState = console?.consoleState() {
            if let state = gameModel.state {
                SavesService.saveState(state, state: newState)
            } else {
                gameModel.setState(newState)
            }
        }
        timer?.invalidate()
        if let modelContext {
            SwiftDataManager.performOnUpdate(context: modelContext)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    private func setupControlButtons() {
        aButton.addAction(UIAction(handler: aButtonPressed), for: .touchDown)
        aButton.addAction(UIAction(handler: aButtonReleased), for: .touchUpInside)
        aButton.addAction(UIAction(handler: aButtonReleased), for: .touchUpOutside)
        
        bButton.addAction(UIAction(handler: bButtonPressed), for: .touchDown)
        bButton.addAction(UIAction(handler: bButtonReleased), for: .touchUpInside)
        bButton.addAction(UIAction(handler: bButtonReleased), for: .touchUpOutside)
        
        leftButton.addAction(UIAction(handler: leftButtonPressed), for: .touchDown)
        leftButton.addAction(UIAction(handler: leftButtonReleased), for: .touchUpInside)
        leftButton.addAction(UIAction(handler: leftButtonReleased), for: .touchUpOutside)
        
        downButton.addAction(UIAction(handler: downButtonPressed), for: .touchDown)
        downButton.addAction(UIAction(handler: downButtonReleased), for: .touchUpInside)
        downButton.addAction(UIAction(handler: downButtonReleased), for: .touchUpOutside)
        
        upButton.addAction(UIAction(handler: upButtonPressed), for: .touchDown)
        upButton.addAction(UIAction(handler: upButtonReleased), for: .touchUpInside)
        upButton.addAction(UIAction(handler: upButtonReleased), for: .touchUpOutside)
        
        rightButton.addAction(UIAction(handler: rightButtonPressed), for: .touchDown)
        rightButton.addAction(UIAction(handler: rightButtonReleased), for: .touchUpInside)
        rightButton.addAction(UIAction(handler: rightButtonReleased), for: .touchUpOutside)
        
        selectButton.addAction(UIAction(handler: selectButtonPressed), for: .touchDown)
        selectButton.addAction(UIAction(handler: selectButtonReleased), for: .touchUpInside)
        selectButton.addAction(UIAction(handler: selectButtonReleased), for: .touchUpOutside)
        
        startButton.addAction(UIAction(handler: startButtonPressed), for: .touchDown)
        startButton.addAction(UIAction(handler: startButtonReleased), for: .touchUpInside)
        startButton.addAction(UIAction(handler: startButtonReleased), for: .touchUpOutside)
        
        view.addSubview(aButton)
        view.addSubview(bButton)
        view.addSubview(leftButton)
        view.addSubview(downButton)
        view.addSubview(upButton)
        view.addSubview(rightButton)
        view.addSubview(selectButton)
        view.addSubview(startButton)
    }
    
    // MARK: EmulatorProtocol
    func pauseEmulation() {
        self.consoleFrameQueueSize = 0
        self.destroyDisplayLink()
    }
    
    func resumeEmulation() {
        self.consoleFrameQueueSize = NesRomViewController.defaultFrameQueueSize
        self.createDisplayLink()
    }
    
    // MARK: - ConsoleSaveStateSelectionDelegate
    func consoleStateSelected(consoleState aConsoleState: EmulatorState) {
        self.consoleQueue.async { [weak self] in
            self?.console?.load(state: aConsoleState)
            self?.console?.set(audioEngineDelegate: self?.audioEngine)
            DispatchQueue.main.async {
                self?.becomeFirstResponder()
            }
        }
    }
    
    func consoleStateSelectionDismissed() {
        self.resumeEmulation()
    }
    
    // MARK: - Button Actions
    
    private func startButtonPressed(_: UIAction?) {
        self.consoleQueue.async { [weak self] in
            self?.console?.set(button: .buttonStart, enabled: true, forControllerAtIndex: 0)
        }
    }
    
    private func startButtonReleased(_: UIAction?) {
        self.consoleQueue.async { [weak self] in
            self?.console?.set(button: .buttonStart, enabled: false, forControllerAtIndex: 0)
        }
    }
    
    private func selectButtonPressed(_: UIAction?) {
        self.consoleQueue.async { [weak self] in
            self?.console?.set(button: .buttonSelect, enabled: true, forControllerAtIndex: 0)
        }
    }
    
    private func selectButtonReleased(_: UIAction?) {
        self.consoleQueue.async { [weak self] in
            self?.console?.set(button: .buttonSelect, enabled: false, forControllerAtIndex: 0)
        }
    }
    
    private func aButtonPressed(_: UIAction?) {
        self.consoleQueue.async { [weak self] in
            self?.console?.set(button: .buttonA, enabled: true, forControllerAtIndex: 0)
        }
    }
    
    private func aButtonReleased(_: UIAction?) {
        self.consoleQueue.async { [weak self] in
            self?.console?.set(button: .buttonA, enabled: false, forControllerAtIndex: 0)
        }
    }
    
    private func bButtonPressed(_: UIAction?) {
        self.consoleQueue.async { [weak self] in
            self?.console?.set(button: .buttonB, enabled: true, forControllerAtIndex: 0)
        }
    }
    
    private func bButtonReleased(_: UIAction?) {
        self.consoleQueue.async { [weak self] in
            self?.console?.set(button: .buttonB, enabled: false, forControllerAtIndex: 0)
        }
    }
    
    private func upButtonPressed(_: UIAction?) {
        self.consoleQueue.async { [weak self] in
            self?.console?.set(button: .buttonUp, enabled: true, forControllerAtIndex: 0)
        }
    }
    
    private func upButtonReleased(_: UIAction?) {
        self.consoleQueue.async { [weak self] in
            self?.console?.set(button: .buttonUp, enabled: false, forControllerAtIndex: 0)
        }
    }
    
    private func downButtonPressed(_: UIAction?) {
        self.consoleQueue.async { [weak self] in
            self?.console?.set(button: .buttonDown, enabled: true, forControllerAtIndex: 0)
        }
    }
    
    private func downButtonReleased(_: UIAction?) {
        self.consoleQueue.async { [weak self] in
            self?.console?.set(button: .buttonDown, enabled: false, forControllerAtIndex: 0)
        }
    }
    
    private func leftButtonPressed(_: UIAction?) {
        self.consoleQueue.async { [weak self] in
            self?.console?.set(button: .buttonLeft, enabled: true, forControllerAtIndex: 0)
        }
    }
    
    private func leftButtonReleased(_: UIAction?) {
        self.consoleQueue.async { [weak self] in
            self?.console?.set(button: .buttonLeft, enabled: false, forControllerAtIndex: 0)
        }
    }
    
    private func rightButtonPressed(_: UIAction?) {
        self.consoleQueue.async { [weak self] in
            self?.console?.set(button: .buttonRight, enabled: true, forControllerAtIndex: 0)
        }
    }
    
    private func rightButtonReleased(_: UIAction?) {
        self.consoleQueue.async { [weak self] in
            self?.console?.set(button: .buttonRight, enabled: false, forControllerAtIndex: 0)
        }
    }
    
    // MARK: - Keyboard
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var didHandleEvent = false
        for press in presses {
            guard let keyCommand = press.key?.charactersIgnoringModifiers else { continue }
            switch keyCommand {
            case UIKeyCommand.inputUpArrow:
                self.upButtonPressed(nil)
                didHandleEvent = true
            case UIKeyCommand.inputDownArrow:
                self.downButtonPressed(nil)
                didHandleEvent = true
            case UIKeyCommand.inputLeftArrow:
                self.leftButtonPressed(nil)
                didHandleEvent = true
            case UIKeyCommand.inputRightArrow:
                self.rightButtonPressed(nil)
                didHandleEvent = true
            case "a":
                self.selectButtonPressed(nil)
                didHandleEvent = true
            case "s":
                self.startButtonPressed(nil)
                didHandleEvent = true
            case "z":
                self.bButtonPressed(nil)
                didHandleEvent = true
            case "x":
                self.aButtonPressed(nil)
                didHandleEvent = true
            default:
                break
            }
        }
        
        if didHandleEvent == false {
            super.pressesBegan(presses, with: event)
        }
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var didHandleEvent = false
        for press in presses {
            guard let keyCommand = press.key?.charactersIgnoringModifiers else { continue }
            
            switch keyCommand {
            case UIKeyCommand.inputUpArrow:
                self.upButtonReleased(nil)
                didHandleEvent = true
            case UIKeyCommand.inputDownArrow:
                self.downButtonReleased(nil)
                didHandleEvent = true
            case UIKeyCommand.inputLeftArrow:
                self.leftButtonReleased(nil)
                didHandleEvent = true
            case UIKeyCommand.inputRightArrow:
                self.rightButtonReleased(nil)
                didHandleEvent = true
            case "a":
                self.selectButtonReleased(nil)
                didHandleEvent = true
            case "s":
                self.startButtonReleased(nil)
                didHandleEvent = true
            case "z":
                self.bButtonReleased(nil)
                didHandleEvent = true
            case "x":
                self.aButtonReleased(nil)
                didHandleEvent = true
            default:
                break
            }
        }
        
        if didHandleEvent == false {
            super.pressesBegan(presses, with: event)
        }
    }
    
    // MARK - Display Link Frame Update
    @objc private func updateFrame() {
        guard self.consoleFramesQueued <= self.consoleFrameQueueSize else { return }
        self.consoleFramesQueued += 1
        
        self.consoleQueue.async { [weak self] in
            self?.console?.stepSeconds(seconds: 1.0 / 60.0)
            DispatchQueue.main.async { [weak self] in
                self?.consoleFramesQueued -= 1
                self?.screen.buffer = self?.console?.screenBuffer ?? PPU.emptyBuffer
            }
        }
    }
    
    // MARK: - Notifications
    @objc private func appResignedActive() {
        self.consoleQueue.suspend()
        self.hasSuspended = true
    }
    
    @objc private func appBecameActive() {
        if self.hasSuspended
        {
            self.consoleQueue.resume()
            self.hasSuspended = false
        }
    }
    
    // MARK: - Private Functions
    
    private func createDisplayLink() {
        self.destroyDisplayLink()
        self.displayLink = CADisplayLink(target: self, selector: #selector(updateFrame))
        self.displayLink?.preferredFramesPerSecond = 60
        self.displayLink?.add(to: RunLoop.current, forMode: RunLoop.Mode.default)
    }
    
    private func destroyDisplayLink() {
        self.displayLink?.isPaused = true
        self.displayLink?.invalidate()
        self.displayLink = nil
    }
    
    /// Update each second
    private func updateTimePlayed() {
        guard let profile, let gameModel else { return }
        profile.timePlayed[gameModel.title, default: 0] += TimeInterval(1)
    }
}
