use clap::Parser;
use tracing_subscriber::{layer::SubscriberExt, Layer};

mod cli;

#[tokio::main]
async fn main() -> Result<(), miette::Error> {
    let cli = crate::cli::Cli::parse();

    // Set up logging
    let mut env_filter = tracing_subscriber::EnvFilter::from_default_env();

    let level_filter = tracing::metadata::LevelFilter::from_level(cli.logging.into());
    let directive = tracing_subscriber::filter::Directive::from(level_filter);
    env_filter = env_filter.add_directive(directive);

    let subscriber = tracing_subscriber::registry::Registry::default()
        .with(tracing_subscriber::fmt::layer().with_filter(env_filter));

    if let Err(e) = tracing::subscriber::set_global_default(subscriber) {
        eprintln!("Failed to set global logging subscriber: {:?}", e);
        std::process::exit(1)
    }
    // Finished setting up logging

    Ok(())
}
