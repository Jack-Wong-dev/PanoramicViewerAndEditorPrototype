import UIKit

/**
 FloatingActionButton dependent on UIWindow.
 */
open class FloatyViewController: UIViewController {
  public let floaty = Floaty()
  var statusBarStyle: UIStatusBarStyle = .default
  
  override open func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(floaty)
  }
  
  override open var preferredStatusBarStyle: UIStatusBarStyle {
    get {
      return statusBarStyle
    }
  }
}
