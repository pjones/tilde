{ fetchurl
}:

{
  # https://www.reddit.com/r/wallpapers/comments/ge4hrd/geometry/
  login = fetchurl {
    url = "https://i.redd.it/tg9ac8kn10x41.jpg";
    sha256 = "0pb32hzrngl06c1icb2hmdq8ja7v1gc2m4ss32ihp6rk45c59lji";
  };

  # https://hipwallpaper.com/hal-wallpapers/
  lock = fetchurl {
    url = "https://cdn.hipwallpaper.com/i/67/96/dZvUD0.png";
    sha256 = "0qj164qbhk4fwj0n14kyira4kka4sccqdgapcdz573bbs7d0pdxi";
  };
}
