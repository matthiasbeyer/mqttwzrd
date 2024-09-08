#[derive(Debug, clap::Parser)]
pub struct Cli {
    #[clap(short, long)]
    pub logging: Level,

    #[clap(short, long)]
    pub bind_addr: std::net::SocketAddr,

    #[clap(short, long)]
    pub port: u16,

    #[clap(short, long)]
    pub mqtt_addr: std::net::SocketAddr,

    #[clap(short, long)]
    pub mqtt_port: u16,
}

#[derive(Default, Debug, Copy, Clone, clap::ValueEnum)]
pub enum Level {
    Error,
    Warn,
    #[default]
    Info,
    Debug,
    Trace,
}

impl From<Level> for tracing::metadata::Level {
    fn from(value: Level) -> Self {
        match value {
            Level::Error => tracing::metadata::Level::ERROR,
            Level::Warn => tracing::metadata::Level::WARN,
            Level::Info => tracing::metadata::Level::INFO,
            Level::Debug => tracing::metadata::Level::DEBUG,
            Level::Trace => tracing::metadata::Level::TRACE,
        }
    }
}
