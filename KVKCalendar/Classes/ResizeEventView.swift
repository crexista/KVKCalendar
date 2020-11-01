//
//  ResizeEventView.swift
//  KVKCalendar
//
//  Created by Sergei Kviatkovskii on 24.10.2020.
//

import UIKit

final class ResizeEventView: UIView {
    
    enum ResizeEventViewType: Int {
        case top, bottom
        
        var tag: Int {
            return rawValue
        }
    }
    
    weak var delegate: ResizeEventViewDelegate?
    
    let event: Event
    
    let mainYOffset: CGFloat = 15
    let originalFrameEventView: CGRect
    
    private lazy var eventView: UIView = {
        let view = UIView()
        view.backgroundColor = event.color?.value ?? event.backgroundColor
        view.addGestureRecognizer(panGesture)
        return view
    }()
    
    private lazy var topView = createPanView(type: .top)
    private lazy var bottomView = createPanView(type: .bottom)
    private let mainHeightOffset: CGFloat = 30
    private let style: Style
    
    var haveNewSize: (needSave: Bool, frame: CGRect) {
        guard originalFrameEventView.height != eventView.frame.height else {
            return (false, .zero)
        }
        
        let newFrame = CGRect(x: originalFrameEventView.origin.x,
                              y: frame.origin.y,
                              width: originalFrameEventView.width,
                              height: eventView.frame.height)
        return (true, newFrame)
    }
    
    private func createPanView(type: ResizeEventViewType) -> UIView {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 30, height: mainYOffset)))
        view.backgroundColor = .clear
        view.tag = type.tag
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(trackGesture))
        view.addGestureRecognizer(gesture)

        return view
    }
    
    private func createCircleView() -> UIView {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 8, height: 8)))
        view.backgroundColor = .white
        view.layer.borderWidth = 1.5
        view.layer.borderColor = event.color?.value.cgColor ?? event.backgroundColor.cgColor
        view.layer.cornerRadius = 4
        return view
    }
    
    private lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(panResizeView))
        return gesture
    }()
    
    init(view: UIView, event: Event, frame: CGRect, style: Style) {
        self.event = event
        self.originalFrameEventView = frame
        self.style = style
        
        var newFrame = frame
        newFrame.origin.y -= mainYOffset
        newFrame.size.height += mainHeightOffset
        super.init(frame: newFrame)
        
        backgroundColor = .clear
        
        eventView.frame = CGRect(origin: CGPoint(x: 0, y: mainYOffset), size: CGSize(width: frame.width, height: frame.height))
        addSubview(eventView)
        eventView.layer.cornerRadius = 5
        
        view.frame = CGRect(origin: .zero, size: eventView.frame.size)
        eventView.addSubview(view)
        
        topView.frame.origin = CGPoint(x: frame.width * 0.8, y: mainYOffset * 0.5)
        addSubview(topView)
        
        bottomView.frame.origin = CGPoint(x: (frame.width * 0.2) - bottomView.frame.width, y: frame.height + (mainYOffset * 0.5))
        addSubview(bottomView)
        
        let topCircleView = createCircleView()
        topCircleView.frame.origin = CGPoint(x: (topView.frame.width * 0.5) - 4, y: topView.frame.height * 0.5 - 4)
        topView.addSubview(topCircleView)
        
        let bottomCircleView = createCircleView()
        bottomCircleView.frame.origin = CGPoint(x: (bottomView.frame.width * 0.5) - 4, y: bottomView.frame.height * 0.5 - 4)
        bottomView.addSubview(bottomCircleView)
    }
    
    func updateHeight() {
        bottomView.frame.origin.y = (frame.height - mainHeightOffset) + (mainYOffset * 0.5)
        eventView.frame.size.height = frame.height - mainHeightOffset
        eventView.subviews.forEach({ $0.frame.size.height = frame.height - mainHeightOffset })
    }
    
    @objc private func trackGesture(gesture: UIPanGestureRecognizer) {
        guard let tag = gesture.view?.tag, let type = ResizeEventViewType(rawValue: tag) else { return }
        
        switch gesture.state {
        case .changed:
            delegate?.didStart(gesture: gesture, type: type)
        case .cancelled, .failed, .ended:
            delegate?.didEnd(gesture: gesture, type: type)
        default:
            break
        }
    }
    
    @objc private func panResizeView(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            alpha = style.event.alphaWhileMoving
            delegate?.didStartMoveResizeEvent(event, gesture: gesture, view: self)
        case .changed:
            delegate?.didChangeMoveResizeEvent(event, gesture: gesture)
        case .cancelled, .ended, .failed:
            if gesture.state == .failed {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
            }
            
            alpha = 1.0
            delegate?.didEndMoveResizeEvent(event, gesture: gesture)
        default:
            break
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol ResizeEventViewDelegate: class {
    func didStart(gesture: UIPanGestureRecognizer, type: ResizeEventView.ResizeEventViewType)
    func didEnd(gesture: UIPanGestureRecognizer, type: ResizeEventView.ResizeEventViewType)
    func didStartMoveResizeEvent(_ event: Event, gesture: UIPanGestureRecognizer, view: UIView)
    func didEndMoveResizeEvent(_ event: Event, gesture: UIPanGestureRecognizer)
    func didChangeMoveResizeEvent(_ event: Event, gesture: UIPanGestureRecognizer)
}
