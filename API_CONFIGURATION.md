# API Configuration Guide

This document explains how to obtain and configure the API keys needed for FamilyFeast.

## Required APIs

### 1. OpenAI API (Optional but Recommended)

**Purpose**: Powers AI recipe suggestions, ingredient parsing, and meal plan generation.

**How to Get Your Key**:

1. Go to [OpenAI Platform](https://platform.openai.com/)
2. Sign up or log in
3. Navigate to API Keys section
4. Click "Create new secret key"
5. Copy the key (it starts with `sk-`)

**Pricing** (as of 2026):
- GPT-4o-mini: ~$0.15 per 1M input tokens, ~$0.60 per 1M output tokens
- Typical cost per recipe suggestion: ~$0.01-0.02
- Budget: $10/month covers ~500-1000 AI interactions

**Configuration**:
```swift
// In FamilyFeastApp.swift or via environment variable
let openAIKey = "sk-your-key-here"
let aiService = AIService(apiKey: openAIKey)
```

**Environment Variable** (Recommended):
```bash
export OPENAI_API_KEY="sk-your-key-here"
```

---

### 2. Spoonacular API (Optional)

**Purpose**: Provides ingredient price estimates and nutritional data.

**How to Get Your Key**:

1. Go to [Spoonacular](https://spoonacular.com/food-api)
2. Sign up for an account
3. Go to your profile/console
4. Copy your API key

**Pricing**:
- **Free Tier**: 150 points/day (~50 recipe lookups)
- **Meal Plan Tier ($19/month)**: 1500 points/day
- **Premium Tier ($49/month)**: 5000 points/day

**Point Costs**:
- Get Recipe Information: 1 point
- Parse Ingredients: 1 point
- Get Price Breakdown: 2 points

**Configuration**:
```swift
let spoonacularKey = "your-spoonacular-key"
let service = SpoonacularService(apiKey: spoonacularKey)
```

**Environment Variable**:
```bash
export SPOONACULAR_API_KEY="your-key-here"
```

---

### 3. CloudKit (Required)

**Purpose**: Multi-user synchronization, family sharing, real-time updates.

**Setup** (Free with Apple Developer Account):

1. **Enable CloudKit in Xcode**:
   - Select your target
   - Go to "Signing & Capabilities"
   - Click "+ Capability"
   - Add "iCloud"
   - Check "CloudKit"

2. **Create or Select Container**:
   - In the iCloud section, click the dropdown
   - Either select an existing container or create new
   - Recommended naming: `iCloud.com.yourteam.familyfeast`

3. **Configure CloudKit Dashboard** (Optional):
   - Go to [CloudKit Console](https://icloud.developer.apple.com/)
   - Select your container
   - Verify record types are created automatically by SwiftData
   - Set up development/production environments

**Cost**: Free up to 1PB of asset storage and unlimited database operations for apps with < 1M users.

---

## Configuration Methods

### Method 1: Environment Variables (Recommended for Development)

**Advantages**:
- Keeps secrets out of source code
- Easy to change without recompiling
- Works with Xcode schemes

**Setup**:

1. **In Terminal**:
   ```bash
   # Add to ~/.zshrc or ~/.bash_profile
   export OPENAI_API_KEY="sk-..."
   export SPOONACULAR_API_KEY="..."
   ```

2. **In Xcode**:
   - Edit Scheme → Run → Arguments
   - Add Environment Variables:
     ```
     OPENAI_API_KEY = sk-your-key
     SPOONACULAR_API_KEY = your-key
     ```

3. **Access in Code**:
   ```swift
   let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
   ```

---

### Method 2: Configuration File (For Production)

**Create**: `Sources/Utilities/Secrets.swift`

```swift
enum Secrets {
    #if DEBUG
    // Development keys
    static let openAIKey = "sk-dev-key"
    static let spoonacularKey = "dev-key"
    #else
    // Production keys (load from keychain or secure storage)
    static let openAIKey = KeychainHelper.retrieve("openai_key") ?? ""
    static let spoonacularKey = KeychainHelper.retrieve("spoonacular_key") ?? ""
    #endif
}
```

**⚠️ IMPORTANT**: Add to `.gitignore`:
```gitignore
# API Keys and Secrets
Sources/Utilities/Secrets.swift
**/Secrets.swift
```

---

### Method 3: Xcode Configuration File

**Create**: `Config.xcconfig`

```xcconfig
OPENAI_API_KEY = sk-your-key-here
SPOONACULAR_API_KEY = your-key-here
```

**Add to `.gitignore`**:
```gitignore
*.xcconfig
Config.xcconfig
```

**Use in Info.plist**:
```xml
<key>OpenAIAPIKey</key>
<string>$(OPENAI_API_KEY)</string>
```

**Access in Code**:
```swift
let key = Bundle.main.object(forInfoDictionaryKey: "OpenAIAPIKey") as? String
```

---

## Security Best Practices

### ✅ DO:
- Use environment variables for development
- Store production keys in iOS Keychain
- Use different keys for dev/staging/production
- Rotate keys regularly
- Monitor API usage for anomalies
- Use API rate limiting on your backend if possible

### ❌ DON'T:
- Commit API keys to Git
- Hardcode keys in source files
- Share keys in screenshots or logs
- Use production keys in debug builds
- Expose keys in client-side code (prefer backend proxy)

---

## Testing Without API Keys

FamilyFeast can run without API keys with limited functionality:

**Without OpenAI**:
- ✅ Manual recipe entry works
- ✅ Voting and meal planning works
- ❌ AI suggestions disabled
- ❌ Smart ingredient parsing disabled

**Without Spoonacular**:
- ✅ Recipe management works
- ✅ Shopping lists generated
- ❌ Price estimates unavailable
- ❌ Nutritional data not fetched

**Without CloudKit**:
- ✅ Local-only mode works
- ❌ Family sharing disabled
- ❌ No multi-device sync

---

## Cost Optimization Tips

### OpenAI:
1. **Use GPT-4o-mini**: 90% cheaper than GPT-4, sufficient for this use case
2. **Cache common queries**: Store frequently used recipe structures
3. **Batch requests**: Process multiple ingredients at once
4. **Set token limits**: Use `max_tokens` parameter to control costs
5. **Implement retries with exponential backoff**: Avoid duplicate charges

### Spoonacular:
1. **Cache API responses**: Store recipe data locally for 30 days
2. **Use free tier wisely**: Prioritize critical features
3. **Fallback to estimates**: Use built-in cost estimation when API unavailable
4. **Batch ingredient lookups**: Combine multiple items in one request

### CloudKit:
1. **Optimize sync frequency**: Use batch updates instead of realtime for non-critical data
2. **Compress images**: Use HEIC format and reasonable resolutions
3. **Clean old data**: Archive completed meal sessions
4. **Use public database for static content**: Recipe catalog doesn't need private sync

---

## Troubleshooting

### "Invalid API Key" Error

**OpenAI**:
- Verify key starts with `sk-`
- Check key is active in OpenAI dashboard
- Ensure no extra spaces in key

**Spoonacular**:
- Verify key in your Spoonacular profile
- Check daily point limit not exceeded
- Wait if rate limited (429 error)

### "CloudKit Not Available"

1. **Check iCloud Sign-in**:
   - Settings → [Your Name] → iCloud
   - Verify signed in

2. **Check Capabilities**:
   - Xcode → Target → Signing & Capabilities
   - Ensure iCloud + CloudKit enabled

3. **Check Container**:
   - Verify container identifier matches code
   - Check container exists in CloudKit Dashboard

### "Network Error"

- Check internet connection
- Verify API endpoints not blocked by firewall
- Check API service status pages
- Implement retry logic with exponential backoff

---

## Production Deployment

For App Store release:

1. **Proxy API Calls**: Create a backend server to hide keys
2. **Rate Limiting**: Implement per-user quotas
3. **Monitoring**: Set up alerts for unusual API usage
4. **Fallbacks**: Ensure app works when APIs are down
5. **Terms of Service**: Comply with OpenAI and Spoonacular ToS

---

## Support

If you encounter issues:

1. Check [OpenAI Status](https://status.openai.com/)
2. Check [Spoonacular Status](https://spoonacular.com/food-api/status)
3. Review CloudKit logs in Xcode console
4. Open an issue on GitHub with error details

---

**Last Updated**: January 2026
