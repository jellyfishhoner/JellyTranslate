using System.Drawing;
using System.Windows.Forms;

namespace JellyTranslate.Windows.UI;

internal sealed class TranslationPopupForm : Form
{
    public TranslationPopupForm(string originalText, string translatedText, string targetLanguage)
    {
        Text = "JellyTranslate";
        Width = 460;
        Height = 280;
        FormBorderStyle = FormBorderStyle.None;
        TopMost = true;
        ShowInTaskbar = false;
        BackColor = Color.FromArgb(18, 21, 29);
        ForeColor = Color.White;
        Padding = new Padding(18);

        var root = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            ColumnCount = 1,
            RowCount = 4,
            BackColor = BackColor
        };
        root.RowStyles.Add(new RowStyle(SizeType.Absolute, 34));
        root.RowStyles.Add(new RowStyle(SizeType.Percent, 35));
        root.RowStyles.Add(new RowStyle(SizeType.Percent, 45));
        root.RowStyles.Add(new RowStyle(SizeType.Absolute, 46));

        var header = new Label
        {
            Text = $"JellyTranslate   MyMemory · Auto → {targetLanguage.ToUpperInvariant()}",
            Dock = DockStyle.Fill,
            Font = new Font("Segoe UI", 10, FontStyle.Bold),
            ForeColor = Color.FromArgb(170, 178, 194)
        };

        var original = BuildTextPanel("Original", originalText, strong: false);
        var translation = BuildTextPanel("Translation", translatedText, strong: true);
        var actions = BuildActions(translatedText);

        root.Controls.Add(header, 0, 0);
        root.Controls.Add(original, 0, 1);
        root.Controls.Add(translation, 0, 2);
        root.Controls.Add(actions, 0, 3);
        Controls.Add(root);
    }

    protected override void OnDeactivate(EventArgs eventArgs)
    {
        base.OnDeactivate(eventArgs);
        Close();
    }

    protected override void OnPaint(PaintEventArgs eventArgs)
    {
        using var borderPen = new Pen(Color.FromArgb(58, 255, 255, 255));
        eventArgs.Graphics.DrawRectangle(borderPen, 0, 0, Width - 1, Height - 1);
        base.OnPaint(eventArgs);
    }

    private static Panel BuildTextPanel(string label, string text, bool strong)
    {
        var panel = new Panel
        {
            Dock = DockStyle.Fill,
            Padding = new Padding(14, 10, 14, 10),
            Margin = new Padding(0, 0, 0, 10),
            BackColor = strong ? Color.FromArgb(42, 48, 62) : Color.FromArgb(23, 27, 36)
        };

        var title = new Label
        {
            Text = label,
            Dock = DockStyle.Top,
            Height = 22,
            Font = new Font("Segoe UI", 9, FontStyle.Bold),
            ForeColor = Color.FromArgb(170, 178, 194)
        };

        var value = new Label
        {
            Text = text,
            Dock = DockStyle.Fill,
            Font = new Font("Segoe UI", strong ? 14 : 10, strong ? FontStyle.Bold : FontStyle.Regular),
            ForeColor = Color.White,
            AutoEllipsis = true
        };

        panel.Controls.Add(value);
        panel.Controls.Add(title);
        return panel;
    }

    private FlowLayoutPanel BuildActions(string translatedText)
    {
        var actions = new FlowLayoutPanel
        {
            Dock = DockStyle.Fill,
            FlowDirection = FlowDirection.LeftToRight,
            BackColor = BackColor
        };

        var copy = BuildButton("Copy");
        copy.Click += (_, _) => Clipboard.SetText(translatedText);

        var close = BuildButton("Close");
        close.Click += (_, _) => Close();

        actions.Controls.Add(copy);
        actions.Controls.Add(close);
        return actions;
    }

    private static Button BuildButton(string text)
    {
        return new Button
        {
            Text = text,
            Width = 86,
            Height = 34,
            Margin = new Padding(0, 8, 10, 0),
            BackColor = Color.FromArgb(102, 217, 198),
            ForeColor = Color.FromArgb(7, 17, 15),
            FlatStyle = FlatStyle.Flat,
            Font = new Font("Segoe UI", 9, FontStyle.Bold)
        };
    }
}
