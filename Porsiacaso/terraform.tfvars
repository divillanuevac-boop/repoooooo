ambiente = "dev" # Ambiente de despliegue (ej. dev, qa, staging, prod); cámbialo si la evaluación pide otro ambiente o valor por defecto.

subredes = { # Mapa de subredes de la VPC; cámbialo si la evaluación exige más/menos subredes o distinta estructura.
  pub_1  = { cidr = "10.0.1.0/24", az = "us-east-1a", publica = true } # Subred pública 1; cambia cidr, az, publica o el nombre de clave si la pauta lo pide.
  pub_2  = { cidr = "10.0.2.0/24", az = "us-east-1b", publica = true } # Subred pública 2; cambia cidr, az, publica o el nombre de clave si la pauta lo pide.
  priv_1 = { cidr = "10.0.3.0/24", az = "us-east-1a", publica = false } # Subred privada 1; cambia cidr, az, publica o el nombre de clave si la pauta lo pide.
  priv_2 = { cidr = "10.0.4.0/24", az = "us-east-1b", publica = false } # Subred privada 2; cambia cidr, az, publica o el nombre de clave si la pauta lo pide.
} # Cierra subredes.

servidores = { # Mapa de instancias EC2 a crear; cámbialo si la evaluación pide otros nombres, cantidades o atributos.
  biblioteca-a = { instance_type = "t3.medium", disk_size = 30, subred = "pub_1" } # Servidor biblioteca-a; cambia instance_type, disk_size, subred o la clave según la pauta.
  biblioteca-b = { instance_type = "t3.medium", disk_size = 30, subred = "pub_1" } # Servidor biblioteca-b; cambia instance_type, disk_size, subred o la clave según la pauta.
  biblioteca-c = { instance_type = "t3.large",  disk_size = 60, subred = "pub_2" } # Servidor biblioteca-c; cambia instance_type, disk_size, subred o la clave según la pauta.
} # Cierra servidores.