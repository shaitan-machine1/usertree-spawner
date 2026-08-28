#[tokio::main(flavor = "current_thread")]
async fn main() {
    if let Err(error) = usertree_spawnerd::app::run().await {
        eprintln!("usertree-spawnerd: fatal: {error:#}");
        std::process::exit(1);
    }
}
