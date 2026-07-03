using JellyTranslate.Windows.Services;
using JellyTranslate.Windows.UI;
using System.Drawing;
using System.Windows.Forms;

namespace JellyTranslate.Windows;

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        try
        {
            ApplicationConfiguration.Initialize();
            Application.ThreadException += (_, eventArgs) => ShowFatalError(eventArgs.Exception);
            AppDomain.CurrentDomain.UnhandledException += (_, eventArgs) =>
            {
                if (eventArgs.ExceptionObject is Exception exception)
                {
                    ShowFatalError(exception);
                }
            };

            Application.Run(new JellyTranslateAppContext());
        }
        catch (Exception exception)
        {
            ShowFatalError(exception);
        }
    }

    private static void ShowFatalError(Exception exception)
    {
        MessageBox.Show(
            exception.Message,
            "JellyTranslate could not start",
            MessageBoxButtons.OK,
            MessageBoxIcon.Error
        );
    }
}

internal sealed class JellyTranslateAppContext : ApplicationContext
{
    private readonly Icon appIcon = Icon.ExtractAssociatedIcon(Application.ExecutablePath) ?? (Icon)SystemIcons.Application.Clone();
    private readonly NotifyIcon notifyIcon;
    private readonly HotKeyWindow hotKeyWindow;
    private readonly ClipboardSelectionService selectionService = new();
    private readonly MyMemoryTranslationService translationService = new();
    private TranslationPopupForm? popup;

    public JellyTranslateAppContext()
    {
        notifyIcon = new NotifyIcon
        {
            Icon = appIcon,
            Text = "JellyTranslate",
            Visible = true,
            ContextMenuStrip = BuildTrayMenu()
        };
        notifyIcon.DoubleClick += (_, _) => ShowTestPopup();

        hotKeyWindow = new HotKeyWindow();
        hotKeyWindow.ShowTranslateRequested += async (_, _) => await TranslateSelectionAsync(replace: false);
        hotKeyWindow.ReplaceRequested += async (_, _) => await TranslateSelectionAsync(replace: true);

        try
        {
            hotKeyWindow.RegisterHotKeys();
            notifyIcon.ShowBalloonTip(
                3200,
                "JellyTranslate is running",
                "Select text and press Ctrl+Alt+T. Double-click this tray icon to test the popup.",
                ToolTipIcon.Info
            );
        }
        catch (Exception exception)
        {
            MessageBox.Show(
                $"{exception.Message}\n\nJellyTranslate is still running in the tray. You can use the tray menu while we fix the hotkey conflict.",
                "JellyTranslate hotkeys are not available",
                MessageBoxButtons.OK,
                MessageBoxIcon.Warning
            );
        }
    }

    private ContextMenuStrip BuildTrayMenu()
    {
        var menu = new ContextMenuStrip();
        menu.Items.Add("Show test popup", null, (_, _) => ShowTestPopup());
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add("Show translation  Ctrl+Alt+T", null, async (_, _) => await TranslateSelectionAsync(replace: false));
        menu.Items.Add("Translate and replace  Ctrl+Alt+R", null, async (_, _) => await TranslateSelectionAsync(replace: true));
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add("Exit", null, (_, _) => ExitThread());
        return menu;
    }

    private void ShowTestPopup()
    {
        ShowPopup("Hello world", "Привет, мир", "ru");
    }

    private async Task TranslateSelectionAsync(bool replace)
    {
        try
        {
            var selectedText = await selectionService.ReadSelectedTextAsync();
            if (string.IsNullOrWhiteSpace(selectedText))
            {
                ShowPopup("No selected text", "Select text in another app, then press Ctrl+Alt+T.");
                return;
            }

            var targetLanguage = LanguagePair.TargetFor(selectedText);

            if (!replace)
            {
                ShowPopup(selectedText, "Translating...", targetLanguage);
            }

            var translatedText = await translationService.TranslateAsync(selectedText, from: "auto", to: targetLanguage);

            if (replace)
            {
                await selectionService.ReplaceSelectedTextAsync(translatedText);
            }

            ShowPopup(selectedText, translatedText, targetLanguage);
        }
        catch (Exception exception)
        {
            ShowPopup("Translation failed", exception.Message, "ru");
        }
    }

    private void ShowPopup(string originalText, string translatedText, string targetLanguage = "ru")
    {
        popup?.Close();
        popup?.Dispose();

        popup = new TranslationPopupForm(originalText, translatedText, targetLanguage)
        {
            StartPosition = FormStartPosition.Manual
        };

        var cursor = Cursor.Position;
        var screen = Screen.FromPoint(cursor).WorkingArea;
        var x = Math.Min(cursor.X + 18, screen.Right - popup.Width - 12);
        var y = Math.Min(cursor.Y + 18, screen.Bottom - popup.Height - 12);
        popup.Location = new Point(Math.Max(screen.Left + 12, x), Math.Max(screen.Top + 12, y));
        popup.Show();
    }

    protected override void ExitThreadCore()
    {
        hotKeyWindow.Dispose();
        notifyIcon.Visible = false;
        notifyIcon.Dispose();
        appIcon.Dispose();
        popup?.Dispose();
        base.ExitThreadCore();
    }
}
