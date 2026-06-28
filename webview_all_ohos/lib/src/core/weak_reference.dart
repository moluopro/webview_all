/// Builds a callback object that captures [reference] weakly.
///
/// This prevents long-lived platform callbacks from keeping controller objects
/// alive after the owning widget or delegate has been disposed.
S withWeakReferenceTo<T extends Object, S extends Object>(
  T reference,
  S Function(WeakReference<T> weakReference) onCreate,
) {
  return onCreate(WeakReference<T>(reference));
}
