using System.Net;
using System.Text.Json;

namespace JellyTranslate.Windows.Services;

internal sealed class MyMemoryTranslationService
{
    private static readonly HttpClient HttpClient = new()
    {
        Timeout = TimeSpan.FromSeconds(12)
    };

    public async Task<string> TranslateAsync(string text, string from, string to)
    {
        var source = LanguagePair.SourceFor(from, text);
        var langPair = $"{source}|{to}";
        var url = "https://api.mymemory.translated.net/get?q="
            + WebUtility.UrlEncode(text)
            + "&langpair="
            + WebUtility.UrlEncode(langPair);

        using var response = await HttpClient.GetAsync(url);
        response.EnsureSuccessStatusCode();

        await using var stream = await response.Content.ReadAsStreamAsync();
        using var json = await JsonDocument.ParseAsync(stream);

        if (json.RootElement.TryGetProperty("responseData", out var responseData)
            && responseData.TryGetProperty("translatedText", out var translatedText))
        {
            var value = WebUtility.HtmlDecode(translatedText.GetString() ?? string.Empty).Trim();
            if (!string.IsNullOrWhiteSpace(value))
            {
                return value;
            }
        }

        throw new InvalidOperationException("MyMemory returned an empty translation.");
    }
}
