# Підключення підтвердження email

FinTrack надсилає листи через Firebase Authentication. Поки Firebase-проєкт не підключений, реєстрація й вхід чесно показують повідомлення про відсутню конфігурацію.

## Налаштування Firebase

1. Створіть проєкт у [Firebase Console](https://console.firebase.google.com/).
2. Відкрийте **Authentication → Sign-in method** і ввімкніть **Email/Password**.
3. У **Project settings → General** скопіюйте **Web API Key**.
4. Запустіть застосунок із цим ключем:

```powershell
flutter run --dart-define="FIREBASE_API_KEY=ВАШ_WEB_API_KEY"
```

Для APK з тією самою конфігурацією:

```powershell
flutter build apk --release --dart-define="FIREBASE_API_KEY=ВАШ_WEB_API_KEY"
```

У Android Studio додайте `--dart-define=FIREBASE_API_KEY=ВАШ_WEB_API_KEY` у **Run → Edit Configurations → Additional run args**.

Після натискання «Зареєструватися» Firebase створить обліковий запис і надішле лист із посиланням. Після переходу за ним користувач повертається в застосунок і натискає «Я підтвердив email». Непідтверджений користувач не переходить на головний екран.

Підтвердження email засвідчує доступ до поштової скриньки, а не перевіряє паспорт чи інший державний документ.
