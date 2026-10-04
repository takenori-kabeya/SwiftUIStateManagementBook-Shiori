# Shiori：書籍のサンプルコード

本リポジトリは、『SwiftUIの状態管理：アプリ開発で学ぶTCA』で開発する旅行計画アプリ「Shiori」のサンプルコードです。

SwiftUIで作ったアプリに機能を追加し、The Composable Architecture（TCA）を導入していく過程を、各時点のコードで確認できます。

## サンプルコード一覧

本書のサンプルコードは、用途ごとに次の3つのリポジトリに分かれています。

| サンプル | リポジトリ | 用途 |
| --- | --- | --- |
| 旅行計画アプリ Shiori | [SwiftUIStateManagementBook-Shiori](https://github.com/takenori-kabeya/SwiftUIStateManagementBook-Shiori) | 本編で開発するアプリです。状態の所有、編集とキャンセル、外部処理、非同期処理の制御、画面遷移などを、アプリへの導入を通して扱います。 |
| カウンタアプリ | [SwiftUIStateManagementBook-Counter](https://github.com/takenori-kabeya/SwiftUIStateManagementBook-Counter) | 小さなアプリで、TCAの基本構造や親子Featureの組み合わせを確認するためのサンプルです。 |
| 天気予報の試作アプリ | [SwiftUIStateManagementBook-WeatherPrototype](https://github.com/takenori-kabeya/SwiftUIStateManagementBook-WeatherPrototype) | 天気予報APIの呼び出しと、取得した情報の表示を確認するための試作アプリです。 |

本編の開発を追うときはShioriを、個々の仕組みを小さなコードで確かめるときはカウンタアプリや天気予報の試作アプリを参照してください。

## 本文とコードの対応

本書では、開発の進行に合わせて設計や実装を変更していきます。本文中のコードを確認するときは、本文に記載されたリンクまたはタグ名から、その時点のコードを参照してください。

## TCAのバージョン

本書のTCAの説明とサンプルコードは、TCA 1.26.1を基準にしています。TCAを導入する前のコードも、開発途中のタグとして収録しています。
