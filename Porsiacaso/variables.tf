variable "region" { # Variable para la región de AWS; cámbiala si la evaluación usa otro nombre de variable.
  type    = string # Tipo cadena de texto; cámbialo si la evaluación exige otro tipo.
  default = "us-east-1" # Región por defecto; cámbiala si la pauta pide otra región (por ejemplo us-west-2 o sa-east-1).
} # Cierra variable "region".

variable "proyecto" { # Variable para el nombre del proyecto; cámbiala si la evaluación usa otro nombre de variable.
  type    = string # Tipo cadena de texto; cámbialo si la evaluación exige otro tipo.
  default = "eduandes" # Valor por defecto del proyecto; cámbialo según el nombre de proyecto que pida la evaluación.
} # Cierra variable "proyecto".

variable "aplicacion" { # Variable para el nombre de la aplicación; cámbiala si la evaluación usa otro nombre de variable.
  type    = string # Tipo cadena de texto; cámbialo si la evaluación exige otro tipo.
  default = "biblioteca" # Valor por defecto de la aplicación; cámbialo según el nombre de app que pida la evaluación.
} # Cierra variable "aplicacion".

variable "responsable" { # Variable para el responsable/autor; cámbiala si la evaluación usa otro nombre de variable.
  type    = string # Tipo cadena de texto; cámbialo si la evaluación exige otro tipo.
  default = "vicente-vidal" # Valor por defecto del responsable; cámbialo por el responsable o estudiante que pida la pauta.
} # Cierra variable "responsable".

variable "ambiente" { # Variable para el entorno de despliegue; cámbiala si la evaluación usa otro nombre de variable.
  description = "Ambiente de despliegue: dev o prod" # Descripción de la variable; actualízala si cambian los ambientes permitidos (ej. dev, qa, prod).
  type        = string # Tipo cadena de texto; cámbialo si la evaluación exige otro tipo.
  default     = "dev" # Ambiente por defecto; cámbialo si la evaluación pide iniciar en otro ambiente.
} # Cierra variable "ambiente".

variable "subredes" { # Variable para el mapa de subredes; cámbiala si la evaluación usa otro nombre de variable.
  type = map(object({ # Mapa de objetos para subredes; ajústalo si la pauta usa lista o estructura distinta.
    cidr    = string # CIDR de la subred; cámbialo si el campo se llama distinto en la pauta.
    az      = string # Zona de disponibilidad; cámbialo si el campo se llama distinto en la pauta.
    publica = bool # Indicador booleano de subred pública/privada; cámbialo si el campo o tipo cambia.
  })) # Cierra tipo de subredes.
} # Cierra variable "subredes".

variable "servidores" { # Variable para el mapa de instancias EC2; cámbiala si la evaluación usa otro nombre de variable.
  type = map(object({ # Mapa de objetos para servidores; ajústalo si la pauta usa lista o atributos distintos.
    instance_type = string # Tipo de instancia EC2; cámbialo si el campo se llama distinto en la pauta.
    disk_size     = number # Tamaño de disco en GB; cámbialo si el campo se llama distinto o cambia de tipo.
    subred        = string # Clave de la subred en var.subredes; cámbialo si el campo o referencia cambia.
  })) # Cierra tipo de servidores.
} # Cierra variable "servidores".

variable "db_password" { # Variable para la contraseña maestra de RDS; cámbiala si la evaluación usa otro nombre de variable.
  description = "Contraseña