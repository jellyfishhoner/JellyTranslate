using JellyTranslate.Windows;
using System.ComponentModel;
using System.Windows.Forms;

namespace JellyTranslate.Windows.Services;

internal sealed class HotKeyWindow : NativeWindow, IDisposable
{
    private const int ShowTranslateHotKeyId = 1;
    private const int ReplaceHotKeyId = 2;

    public event EventHandler? ShowTranslateRequested;
    public event EventHandler? ReplaceRequested;

    public HotKeyWindow()
    {
        CreateHandle(new CreateParams());
    }

    public void RegisterHotKeys()
    {
        RegisterHotKeyOrThrow(ShowTranslateHotKeyId, Keys.T);
        RegisterHotKeyOrThrow(ReplaceHotKeyId, Keys.R);
    }

    private void RegisterHotKeyOrThrow(int id, Keys key)
    {
        var didRegister = NativeMethods.RegisterHotKey(Handle, id, NativeMethods.ModControl | NativeMethods.ModAlt, (uint)key);
        if (!didRegister)
        {
            throw new Win32Exception($"Could not register Ctrl+Alt+{key}. Another app may already use it.");
        }
    }

    protected override void WndProc(ref Message message)
    {
        if (message.Msg == NativeMethods.WmHotKey)
        {
            var id = message.WParam.ToInt32();
            if (id == ShowTranslateHotKeyId)
            {
                ShowTranslateRequested?.Invoke(this, EventArgs.Empty);
                return;
            }

            if (id == ReplaceHotKeyId)
            {
                ReplaceRequested?.Invoke(this, EventArgs.Empty);
                return;
            }
        }

        base.WndProc(ref message);
    }

    public void Dispose()
    {
        NativeMethods.UnregisterHotKey(Handle, ShowTranslateHotKeyId);
        NativeMethods.UnregisterHotKey(Handle, ReplaceHotKeyId);
        DestroyHandle();
    }
}
