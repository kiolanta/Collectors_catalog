# Supabase Storage Setup Guide

## 1. Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up or log in
3. Click **"New Project"**
4. Enter project details:
   - **Name**: collectors-catalog (or your choice)
   - **Database Password**: (generate and save it)
   - **Region**: Choose closest to your users
5. Wait for project to initialize (~2 minutes)

## 2. Create Storage Bucket

1. In your Supabase project, go to **Storage** from the left sidebar
2. Click **"New bucket"**
3. Enter bucket details:
   - **Name**: `item-images`
   - **Public bucket**: ✅ Enable (so images are publicly accessible)
   - **File size limit**: 5 MB (recommended)
   - **Allowed MIME types**: `image/*` (all image types)
4. Click **"Create bucket"**

## 3. Configure Bucket Policies (Optional but Recommended)

Go to **Storage → item-images → Policies**

### Allow Public Read Access
```sql
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'item-images' );
```

### Allow Authenticated Users to Upload
```sql
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'item-images' 
  AND auth.role() = 'authenticated'
);
```

### Allow Users to Update Their Own Files
```sql
CREATE POLICY "Users can update own files"
ON storage.objects FOR UPDATE
USING ( 
  bucket_id = 'item-images'
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

### Allow Users to Delete Their Own Files
```sql
CREATE POLICY "Users can delete own files"
ON storage.objects FOR DELETE
USING ( 
  bucket_id = 'item-images'
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

## 4. Get Your Supabase Credentials

1. Go to **Settings → API** (gear icon in sidebar)
2. Copy these values:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon (public) key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

## 5. Update Your Flutter App

Open `lib/main.dart` and replace the placeholder values:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',        // Replace with Project URL
  anonKey: 'YOUR_SUPABASE_ANON_KEY', // Replace with anon key
);
```

### Example:
```dart
await Supabase.initialize(
  url: 'https://abcdefghijk.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprIiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODAwMDAwMDAsImV4cCI6MTk5NTU3NjAwMH0.xxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
);
```

## 6. Install Dependencies

Run in your terminal:
```bash
flutter pub get
```

## 7. Test Image Upload

1. Run your app
2. Go to **Add Item** page
3. Select an image from gallery
4. Fill in the form and save
5. Check your Supabase Storage dashboard to see the uploaded image!

## How It Works

### File Structure in Supabase
Images are organized by user ID:
```
item-images/
├── user_id_1/
│   ├── user_id_1_1234567890.jpg
│   └── user_id_1_1234567891.png
└── user_id_2/
    └── user_id_2_1234567892.jpg
```

### Image URLs
After upload, you get a public URL like:
```
https://xxxxx.supabase.co/storage/v1/object/public/item-images/user_id/filename.jpg
```

This URL is saved in Firestore and used to display images in your app.

## Troubleshooting

### Images not showing?
- Check bucket is set to **Public**
- Verify URL is correct in Firestore
- Check browser console for CORS errors

### Upload fails?
- Ensure `supabase_flutter` package is installed
- Verify Supabase credentials in `main.dart`
- Check file size (default limit is 5MB)
- Ensure user is authenticated in Firebase

### Storage policies not working?
- Make sure RLS (Row Level Security) is enabled
- Double-check policy SQL syntax
- Test with authenticated user (Firebase Auth)

## Free Tier Limits

Supabase Free Plan includes:
- **Storage**: 1 GB
- **Bandwidth**: 2 GB per month
- **File uploads**: Unlimited

Perfect for development and small apps!

## Security Notes

⚠️ **Never commit your Supabase keys to Git!**

Consider using environment variables:
1. Create `.env` file (add to `.gitignore`)
2. Use `flutter_dotenv` package
3. Load credentials from environment

---

✅ **Setup Complete!** Your app now stores images on Supabase Storage.
