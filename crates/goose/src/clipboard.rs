/// Copies text to the system clipboard, returning whether it succeeded.
///
/// Android has no `arboard` backend, so Termux uses `termux-clipboard-set`
/// from the `termux-api` package when it is installed.
pub fn copy(text: &str) -> bool {
    #[cfg(not(target_os = "android"))]
    {
        arboard::Clipboard::new()
            .and_then(|mut clipboard| clipboard.set_text(text))
            .is_ok()
    }

    #[cfg(target_os = "android")]
    {
        std::process::Command::new("termux-clipboard-set")
            .arg(text)
            .status()
            .is_ok_and(|status| status.success())
    }
}
