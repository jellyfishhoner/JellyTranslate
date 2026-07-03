using System.Text.RegularExpressions;

namespace JellyTranslate.Windows.Services;

internal static partial class LanguagePair
{
    public static string TargetFor(string text)
    {
        return CyrillicRegex().IsMatch(text) ? "en" : "ru";
    }

    public static string SourceFor(string source, string text)
    {
        if (!string.Equals(source, "auto", StringComparison.OrdinalIgnoreCase))
        {
            return source;
        }

        return CyrillicRegex().IsMatch(text) ? "ru" : "en";
    }

    [GeneratedRegex(@"\p{IsCyrillic}")]
    private static partial Regex CyrillicRegex();
}
