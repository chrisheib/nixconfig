{ maccel, ... }:
{
  imports = [
    maccel.nixosModules.default
  ];

  hardware.maccel = {
    enable = true;
    enableCli = true; # Optional

    parameters = {
      # Common (all modes)
      yxRatio = 1.0;
      inputDpi = 1000.0;
      angleRotation = 0.0;

      # Linear mode
      # mode = "linear";
      # sensMultiplier = 0.8;
      # acceleration = 0.025;
      # offset = 5.0;
      # outputCap = 2.0;

      # Natural mode
      mode = "natural";
      sensMultiplier = 0.6;
      decayRate = 0.2;
      offset = 5.0;
      limit = 1.8;

      # # Synchronous mode
      # gamma = 1.0;
      # smooth = 0.5;
      # motivity = 2.5;
      # syncSpeed = 10.0;
    };
  };

  # To use maccel CLI/TUI without sudo
  users.groups.maccel.members = [ "stschiff" ];
}
