//
//  BrowserDetailCell.swift
//  Ubiquity
//
//  Created by sagesse on 16/03/2017.
//  Copyright © 2017 SAGESSE. All rights reserved.
//

import UIKit

internal protocol BrowserDetailCellDelegate: class {
    
    func browserDetailCell(_ browserDetailCell: BrowserDetailCell, shouldBeginRotationing asset: Asset) -> Bool
    func browserDetailCell(_ browserDetailCell: BrowserDetailCell, didEndRotationing asset: Asset, at orientation: UIImageOrientation)
}

internal class BrowserDetailCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        _setup()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _setup()
    }
    deinit {
        // on destory if not the end display, need to manually call it
        guard let asset = _asset, let library = _library else {
            return
        }
        // call end display
        endDisplay(with: asset, in: library)
    }
    
    // event delegate
    weak var delegate: BrowserDetailCellDelegate?
    
    // display asset
    func willDisplay(with asset: Asset, in library: Library, orientation: UIImageOrientation) {
        logger.trace?.write(asset.ub_localIdentifier)
        
        // update ata
        _asset = asset
        _library = library
        _orientation = orientation
        
        // update util
        if let progress = _progress {
            // default is 1(auto hidden)
            progress.setValue(1, animated: false)
        }
        if let console = _console, asset.ub_allowsPlay {
            // if the asset allows play, display console
            // defaults is stop
            console.setState(.stop, animated: false)
        }
        
        // update canvas
        _containerView?.contentSize = .init(width: asset.ub_pixelWidth, height: asset.ub_pixelHeight)
        _containerView?.zoom(to: bounds , with: orientation, animated: false)
        
        // update content
        (_contentView as? Displayable)?.willDisplay(with: asset, in: library, orientation: orientation)
        (_detailView as? Displayable)?.willDisplay(with: asset, in: library, orientation: orientation)
    }
    // end display asset
    func endDisplay(with asset: Asset, in library: Library) {
        logger.trace?.write(asset.ub_localIdentifier)
        
        // update content
        (_contentView as? Displayable)?.endDisplay(with: asset, in: library)
        (_detailView as? Displayable)?.endDisplay(with: asset, in: library)
    }
    
    /// update content inset
    func updateContentInset(_ contentInset: UIEdgeInsets, forceUpdate: Bool) {
        logger.trace?.write(contentInset)
        
        _contentInset = contentInset
        
        // need update layout
        setNeedsLayout()
        
        guard forceUpdate else {
            return
        }
        layoutIfNeeded()
    }
    
    // update subview layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // update utility view
        _progress?.center = _progressCenter
        _console?.center = _consoleCenter
    }
    
    private func _setup() {
        
        // make detail & container view
        _detailView = (type(of: self).detailViewClass as? UIView.Type)?.init()
        _containerView = contentView as? CanvasView
        
        // setup container view if needed
        if let containerView = _containerView {
            containerView.delegate = self
            // add tap recognizer
            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(_handleTap(_:)))
            let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(_handleDoubleTap(_:)))
            
            doubleTapRecognizer.numberOfTapsRequired = 2
            tapRecognizer.numberOfTapsRequired = 1
            tapRecognizer.require(toFail: doubleTapRecognizer)
            
            containerView.addGestureRecognizer(doubleTapRecognizer)
            containerView.addGestureRecognizer(tapRecognizer)
        }
        // setup detail view if needed
        if let detailView = _detailView {
            //  content view
            let contentView = DisplayView(frame: detailView.bounds)
            _contentView = contentView
            
            _detailView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            _containerView?.addSubview(contentView)
            
            _contentView?.clipsToBounds = true
            _contentView?.addSubview(detailView)
            
            // If the detail to support the operation, set the operation delegate
            (_detailView as? Displayable)?.displayerDelegate = self
            (_detailView as? Operable)?.operaterDelegate = self
        }
        // setup console
        _console = ConsoleProxy(frame: .init(x: 0, y: 0, width: 70, height: 70), owner: self)
        _console?.addTarget(self, action: #selector(_handleCommand(_:)), for: .touchUpInside)
        // setup progress
        _progress = ProgressProxy(frame: .init(x: 0, y: 0, width: 24, height: 24), owner: self)
        _progress?.addTarget(self, action: #selector(_handleRetry(_:)), for: .touchUpInside)
    }
    
    // data
    fileprivate var _asset: Asset?
    fileprivate var _library: Library?
    fileprivate var _orientation: UIImageOrientation = .up
    
    // config
    fileprivate var _contentInset: UIEdgeInsets = .zero
    fileprivate var _indicatorInset: UIEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8)
    fileprivate var _draggingContentOffset: CGPoint?
    
    // state
    fileprivate var _isZooming: Bool = false
    fileprivate var _isDragging: Bool = false
    fileprivate var _isRotationing: Bool = false
    
    // content
    fileprivate var _detailView: UIView?
    fileprivate var _contentView: UIView?
    fileprivate var _containerView: CanvasView?
    
    // progress
    fileprivate var _progress: ProgressProxy?
    fileprivate var _progressCenter: CGPoint {
        // If no progress or detailview center is zero
        guard let contentView = _contentView, let progress = _progress else {
            return .zero
        }
        let rect1 = convert(contentView.bounds, from: contentView)
        let rect2 = UIEdgeInsetsInsetRect(bounds, _contentInset)
        
        let x = min(max(rect1.maxX, min(max(rect1.minX, rect2.minX) + rect1.width, rect2.maxX)), rect2.maxX)
        let y = min(rect1.maxY, rect2.maxY)
        
        return .init(x: x - _indicatorInset.right - progress.bounds.midX,
                     y: y - _indicatorInset.bottom - progress.bounds.midY)
    }
    
    // console
    fileprivate var _console: ConsoleProxy?
    fileprivate var _consoleCenter: CGPoint {
        return .init(x: bounds.midX,
                     y: bounds.midY)
    }
}

/// dynamic class support
extension BrowserDetailCell {
    // dynamically generated class
    dynamic class func `dynamic`(with viewClass: AnyClass) -> AnyClass {
        let name = "\(NSStringFromClass(self))<\(NSStringFromClass(viewClass))>"
        // if the class has been registered, ignore
        if let newClass = objc_getClass(name) as? AnyClass {
            return newClass
        }
        // if you have not registered this, dynamically generate it
        let newClass: AnyClass = objc_allocateClassPair(self, name, 0)
        let method: Method = class_getClassMethod(self, #selector(getter: detailViewClass))
        objc_registerClassPair(newClass)
        // because it is a class method, it can not used class, need to use meta class
        guard let metaClass = objc_getMetaClass(name) as? AnyClass else {
            return newClass
        }
        let getter: @convention(block) () -> AnyClass = {
            return viewClass
        }
        // add class method
        class_addMethod(metaClass, #selector(getter: detailViewClass), imp_implementationWithBlock(unsafeBitCast(getter, to: AnyObject.self)), method_getTypeEncoding(method))
        return newClass
    }
    // provide content view of class
    dynamic class var contentViewClass: AnyClass {
        return CanvasView.self
    }
    // provide detail view of class
    dynamic class var detailViewClass: AnyClass {
        return UIView.self
    }
    // provide content view of class, iOS 8+
    fileprivate dynamic class var _contentViewClass: AnyClass {
        return contentViewClass
    }
}

/// event support
extension BrowserDetailCell {
    
    fileprivate dynamic func _handleRetry(_ sender: Any) {
        logger.trace?.write()
        
        // check the state of the data
        guard let asset = _asset, let library = _library else {
            return
        }
        // recall display, to refresh the data
        (_detailView as? Displayable)?.willDisplay(with: asset, in: library, orientation: _orientation)
    }
    fileprivate dynamic func _handleCommand(_ sender: Any) {
        logger.trace?.write()
        play()
    }
    
    fileprivate dynamic func _handleTap(_ sender: UITapGestureRecognizer) {
        logger.trace?.write()
        
        guard let detailView = _detailView else {
            return
        }
        
        if !detailView.ub_isFullscreen {
            detailView.ub_enterFullscreen(animated: true)
        } else {
            detailView.ub_exitFullscreen(animated: true)
        }
    }
    fileprivate dynamic func _handleDoubleTap(_ sender: UITapGestureRecognizer) {
        logger.trace?.write()
        guard let containerView = _containerView else {
            return
        }
        let location = sender.location(in: _contentView)
        // zoome operator wait to next run loop
        DispatchQueue.main.async {
            if containerView.zoomScale != containerView.minimumZoomScale {
                containerView.setZoomScale(containerView.minimumZoomScale, at: location, animated: true)
            } else {
                containerView.setZoomScale(containerView.maximumZoomScale, at: location, animated: true)
            }
        }
    }
}

/// canvas view support
extension BrowserDetailCell: CanvasViewDelegate {
    
    func viewForZooming(in canvasView: CanvasView) -> UIView? {
        return _contentView
    }
    
    func canvasViewDidScroll(_ canvasView: CanvasView) {
        //logger.trace?.write(canvasView.contentOffset, canvasView.isDecelerating, canvasView.isDragging, canvasView.isTracking)
        
        // update progress
        _progress?.center = _progressCenter
    }
    func canvasViewDidZoom(_ canvasView: CanvasView) {
        
        // update progress
        _progress?.center = _progressCenter
    }
    
    func canvasViewWillEndDragging(_ canvasView: CanvasView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        logger.trace?.write()
        // record the content offset of the end
        _draggingContentOffset = targetContentOffset.move()
    }
    
    func canvasViewWillBeginDragging(_ canvasView: CanvasView) {
        logger.trace?.write()
        // update canvas view status
        _isDragging = true
        // update console status
        _console?.setIsHidden(true, animated: true)
        // at the start of the clear, prevent invalid content offset
        _draggingContentOffset = nil
    }
    func canvasViewWillBeginZooming(_ canvasView: CanvasView, with view: UIView?) {
        logger.trace?.write()
        // update canvas view status
        _isZooming = true
        // update console status
        _console?.setIsHidden(true, animated: true)
    }
    func canvasViewShouldBeginRotationing(_ canvasView: CanvasView, with view: UIView?) -> Bool {
        logger.trace?.write()
        // if the item is nil, are not allowed to rotate
        guard let asset = _asset else {
            return false
        }
        // update canvas view status
        _isRotationing = true
        // update progress status
        _progress?.center = _progressCenter
        _progress?.setIsHidden(true, animated: false)
        // update console status
        _console?.setIsHidden(true, animated: true)
        
        // notice delegate
        return delegate?.browserDetailCell(self, shouldBeginRotationing: asset) ?? true
    }
    
    func canvasViewDidEndDecelerating(_ canvasView: CanvasView) {
        logger.trace?.write()
        // update canvas view status
        _isDragging = false
        // if is rotationing, delay update
        if !_isRotationing {
            _console?.setIsHidden(false, animated: true)
        }
        // clear, is end decelerate
        _draggingContentOffset = nil
    }
    func canvasViewDidEndDragging(_ canvasView: CanvasView, willDecelerate decelerate: Bool) {
        logger.trace?.write()
        // if you are slow, delay processing
        guard !decelerate else {
            return
        }
        // update canvas view status
        _isDragging = false
        // if is rotationing, delay update
        if !_isRotationing {
            _console?.setIsHidden(false, animated: true)
        }
        // clear, is end dragg but no decelerat
        _draggingContentOffset = nil
    }
    func canvasViewDidEndZooming(_ canvasView: CanvasView, with view: UIView?, atScale scale: CGFloat) {
        logger.trace?.write()
        // update canvas view status
        _isZooming = false
        // if is rotationing, delay update
        if !_isRotationing {
            _console?.setIsHidden(false, animated: true)
        }
    }
    func canvasViewDidEndRotationing(_ canvasView: CanvasView, with view: UIView?, atOrientation orientation: UIImageOrientation) {
        logger.trace?.write()
        // if the item is nil, are not allowed to rotate
        guard let asset = _asset, let library = _library else {
            return
        }
        // update canvas view status
        _isRotationing = false
        // update content orientation
        _orientation = orientation
        // update display
        (_contentView as? Displayable)?.willDisplay(with: asset, in: library, orientation: orientation)
        (_detailView as? Displayable)?.willDisplay(with: asset, in: library, orientation: orientation)
        // update progress
        _progress?.center = _progressCenter
        _progress?.setIsHidden(false, animated: true)
        
        // update console status
        _console?.setIsHidden(false, animated: true)
        
        // notice delegate
        delegate?.browserDetailCell(self, didEndRotationing: asset, at: orientation)
    }
}

/// provide public accessor support
extension BrowserDetailCell {
    
    var ub_detailView: UIView? {
        return _detailView
    }
    var ub_contentView: UIView? {
        return _contentView
    }
    var ub_containerView: CanvasView? {
        return _containerView
    }
    var ub_draggingContentOffset: CGPoint? {
        return _draggingContentOffset
    }
}

/// custom transition support
extension BrowserDetailCell: TransitioningView {
    
    var ub_frame: CGRect {
        guard let containerView = _containerView, let contentView = _contentView else {
            return .zero
        }
        let center = containerView.convert(contentView.center, from: contentView.superview)
        let bounds = contentView.frame.applying(.init(rotationAngle: _orientation.ub_angle))
        
        let c1 = containerView.convert(center, to: window)
        let b1 = containerView.convert(bounds, to: window)
        
        return .init(x: c1.x - b1.width / 2, y: c1.y - b1.height / 2, width: b1.width, height: b1.height)
    }
    var ub_bounds: CGRect {
        guard let contentView = _contentView else {
            return .zero
        }
        let bounds = contentView.frame.applying(.init(rotationAngle: _orientation.ub_angle))
        return .init(origin: .zero, size: bounds.size)
    }
    var ub_transform: CGAffineTransform {
        guard let containerView = _containerView else {
            return .identity
        }
        return containerView.contentTransform.rotated(by: _orientation.ub_angle)
    }
    func ub_snapshotView(with context: TransitioningContext) -> UIView? {
        let view = _contentView?.snapshotView(afterScreenUpdates: context.ub_operation.appear)
        view?.transform = .init(rotationAngle: -_orientation.ub_angle)
        return view
    }
    
    func ub_transitionDidStart(_ context: TransitioningContext) {
        logger.trace?.write(context.ub_operation)
        
        // restore util view status
        _console?.setIsHidden(true, animated: false)
        _progress?.setIsHidden(true, animated: false)
    }
    func ub_transitionDidEnd(_ didComplete: Bool) {
        logger.trace?.write(didComplete)
        
        // restore util view status
        _console?.setIsHidden(false, animated: true)
        _progress?.setIsHidden(false, animated: true)
    }
}

/// operation support
extension BrowserDetailCell: DisplayableDelegate {
    
    /// Tell the delegate that the remote server requested.
    func displayer(_ displayer: Displayable, didStartRequest asset: Asset) {
        logger.trace?.write()
        
        // reset to default status
        _progress?.setValue(0, animated: false)
    }
    
    /// Periodically informs the delegate of the progress.
    func displayer(_ displayer: Displayable, didReceive progress: Double) {
        logger.trace?.write(progress)
        
        // update progress
        _progress?.setValue(progress, animated: true)
    }
    
    /// Tells the delegate that the task finished receive image.
    func displayer(_ displayer: Displayable, didComplete error: Error?) {
        logger.trace?.write()
        
        // check complete status
        guard let error = error else {
            return
        }
        logger.error?.write(error)
        // -1 is error, enable tap event to retry
        _progress?.setValue(-1, animated: false)
    }
}

/// operation support
extension BrowserDetailCell: OperableDelegate {
    
    func play() {
        // must provide the context
        guard let console = _console, let detailView = _detailView as? Operable else {
            return
        }
        // if is stopped, click goto prepare
        guard console.state == .stop else {
            return
        }
        logger.trace?.write()
        // update the status for waiting
        console.setState(.waiting, animated: true)
        // start playing enter fullscreen mode
        if !ub_isFullscreen {
            ub_enterFullscreen(animated: true)
        }
        
        // prepare player
        DispatchQueue.main.async {
            detailView.play()
        }
    }
    func stop() {
        // must provide the context
        guard let console = _console, let detailView = _detailView as? Operable else {
            return
        }
        // if is playing or waiting, click goto stop
        guard console.state != .none && console.state != .stop else {
            return
        }
        logger.trace?.write()
        // update the status for stop
        console.setState(.stop, animated: true)
        // stop player
        detailView.stop()
    }
    
    func operable(didPrepare operable: Operable, asset: Asset) {
        logger.trace?.write()
        
        operable.play()
    }
    func operable(didStartPlay operable: Operable, asset: Asset) {
        logger.trace?.write()
        
        _console?.setState(.playing, animated: true)
    }
    func operable(didStop operable: Operable, asset: Asset) {
        logger.trace?.write()
        
        _console?.setState(.stop, animated: true)
    }
    
    func operable(didStalled operable: Operable, asset: Asset) {
        logger.trace?.write()
        
        _console?.setState(.waiting, animated: true)
    }
    func operable(didSuspend operable: Operable, asset: Asset) {
        logger.trace?.write()
        // nothing
        _console?.setState(.stop, animated: true)
    }
    func operable(didResume operable: Operable, asset: Asset) {
        logger.trace?.write()
        
        _console?.setState(.playing, animated: true)
    }
    
    func operable(didFinish operable: Operable, asset: Asset) {
        logger.trace?.write()
        
        _console?.setState(.stop, animated: true)
    }
    func operable(didOccur operable: Operable, asset: Asset, error: Error?) {
        logger.trace?.write()
        
        _console?.setState(.stop, animated: true)
    }
}
