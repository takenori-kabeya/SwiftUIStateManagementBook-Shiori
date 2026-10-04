/// ホストアプリ経由でテストから `TestStore` 等を使えるようにする。
/// （テストターゲットへ TCA を二重リンクすると PerceptionCore のリンカ失敗が起きるため）
@_exported import ComposableArchitecture
