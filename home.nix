{ ... }:

{
  # Load the real file:
  imports = [ ./home ];

  # Make this machine an X server:
  tilde = {
    enable = true;
    xsession.enable = true;
  };
}
