using System.Windows.Forms;

namespace JellyTranslate.Windows.Services;

internal sealed class ClipboardSelectionService
{
    public async Task<string> ReadSelectedTextAsync()
    {
        var previousData = Clipboard.GetDataObject();

        Clipboard.Clear();
        SendKeys.SendWait("^c");

        var selectedText = await WaitForClipboardTextAsync();

        if (previousData is not null)
        {
            Clipboard.SetDataObject(previousData);
        }

        return selectedText.Trim();
    }

    public async Task ReplaceSelectedTextAsync(string replacement)
    {
        var previousData = Clipboard.GetDataObject();

        Clipboard.SetText(replacement);
        await Task.Delay(80);
        SendKeys.SendWait("^v");
        await Task.Delay(220);

        if (previousData is not null)
        {
            Clipboard.SetDataObject(previousData);
        }
    }

    private static async Task<string> WaitForClipboardTextAsync()
    {
        for (var attempt = 0; attempt < 10; attempt += 1)
        {
            await Task.Delay(45);
            if (Clipboard.ContainsText())
            {
                return Clipboard.GetText();
            }
        }

        return string.Empty;
    }
}
