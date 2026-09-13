# Сборка «Хватайки» без компьютера

Проект содержит GitHub Actions workflow `.github/workflows/build-rustore.yml`.
Он собирает подписанный AAB для RuStore в облаке GitHub.

## Что нужно сделать с телефона

1. Создать аккаунт GitHub и новый **Private repository**.
2. Загрузить в репозиторий все файлы этого проекта, сохранив папки `scripts`, `scenes`, `assets`, `audio`, `store` и `.github/workflows`.
3. В репозитории открыть **Settings → Secrets and variables → Actions → New repository secret**.
4. Добавить три секретных значения:
   - `RUSTORE_KEYSTORE_B64` — Base64 содержимое вашего release keystore.
   - `RUSTORE_KEYSTORE_PASSWORD` — пароль keystore.
   - `RUSTORE_KEY_ALIAS` — alias ключа.
5. Открыть **Actions → Build Khvataika for RuStore → Run workflow**.
6. После успешной сборки открыть результат workflow и скачать artifact `khvataika-1.13.6-rustore-aab`.

## Важно про ключ подписи

Не публикуйте keystore, пароль или alias в обычных файлах репозитория. Ключ нужен для последующих обновлений приложения. Храните его в безопасном месте.

Если keystore ещё нет, его можно создать на Android-телефоне через приложение/терминал с Java keytool. Не удаляйте его после первой публикации.
