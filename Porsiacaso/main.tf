provider "aws" { # Bloque del proveedor de AWS; cámbialo si la evaluación exige otro proveedor o alias.
  region = var.region # Región de AWS; cámbialo si se pide una región fija o variable distinta.
} # Cierra el bloque provider.

locals { # Valores calculados internos; ajusta las claves o expresiones si la pauta pide otros cálculos.
  common_tags = { # Etiquetas base compartidas; agrega o quita etiquetas si la pauta lo solicita.
    Proyecto    = var.proyecto # Nombre de etiqueta o variable del proyecto; cámbialo si la pauta usa otro nombre.
    Ambiente    = var.ambiente # Nombre de etiqueta o variable del ambiente; cámbialo si la pauta usa otro nombre.
    Responsable = var.responsable # Nombre de etiqueta o variable del responsable; cámbialo si la pauta lo exige.
  } # Cierra common_tags.

  subredes_publicas = [for k, v in aws_subnet.main : v.id if var.subredes[k].publica] # Filtra subredes públicas; cámbialo si el atributo booleano en var.subredes tiene otro nombre.
  subredes_privadas = [for k, v in aws_subnet.main : v.id if !var.subredes[k].publica] # Filtra subredes privadas; cámbialo si el criterio de subred privada cambia.

  clase_rds = lookup({ # Mapea tamaño de RDS según ambiente; cambia las clases de instancia si la pauta exige otras.
    dev  = "db.t3.micro" # Clase RDS para dev; cámbiala si la evaluación pide otro tipo de instancia.
    prod = "db.t3.small" # Clase RDS para prod; cámbiala si la evaluación pide otro tipo de instancia.
  }, var.ambiente, "db.t3.micro") # Variable de ambiente y valor por defecto; cámbialos si cambia la variable o el fallback.
} # Cierra el bloque locals.

data "aws_ami" "linux" { # Busca la AMI base; cámbialo si la evaluación pide otra familia de SO o propietario.
  most_recent = true # Toma la AMI más reciente; cámbialo a false si exigen fijar una versión exacta.
  owners      = ["amazon"] # Dueño de la AMI; cámbialo si piden otro owner o ID de AMI directo.
  filter { # Filtro para seleccionar la AMI; ajústalo si cambian los criterios de búsqueda.
    name   = "name" # Nombre del filtro de AMI; cámbialo si filtran por otro atributo como virtualization-type.
    values = ["al2023-ami-2023*-x86_64"] # Patrón de nombre de AMI (Amazon Linux 2023); cámbialo si piden Ubuntu, Debian, ARM o versión específica.
  } # Cierra filter.
} # Cierra data "aws_ami" "linux".

# --- VPC Y SUBREDES --- # Sección de red principal; comenta o ajusta si la VPC viene precreada o importada.
resource "aws_vpc" "main" { # Recurso VPC principal; cámbialo si la pauta pide usar una VPC existente en vez de crearla.
  cidr_block           = "10.0.0.0/16" # Bloque CIDR de la VPC; cámbialo si la evaluación exige otro rango IP o variable.
  enable_dns_hostnames = true # Habilita DNS hostnames; cámbialo a false solo si la evaluación lo prohíbe.
  tags                 = merge(local.common_tags, { Name = "vpc-${var.proyecto}-${var.ambiente}" }) # Nombre y tags de la VPC; cámbialo si la pauta exige otra convención de nombres.
} # Cierra aws_vpc.main.

resource "aws_internet_gateway" "igw" { # Internet Gateway para salida a internet; quítalo o ajústalo si no hay internet público.
  vpc_id = aws_vpc.main.id # Asocia el IGW a la VPC main; cámbialo si apunta a otra VPC.
  tags   = merge(local.common_tags, { Name = "igw-${var.proyecto}" }) # Nombre y tags del IGW; cámbialo si la pauta pide otro formato de nombre.
} # Cierra aws_internet_gateway.igw.

resource "aws_subnet" "main" { # Crea subredes dinámicamente desde var.subredes; ajusta si se definen subredes fijas.
  for_each                = var.subredes # Mapa de subredes de entrada; cámbialo si la variable se llama distinto.
  vpc_id                  = aws_vpc.main.id # VPC donde se crean las subredes; cámbialo si usas otra VPC.
  cidr_block              = each.value.cidr # CIDR de cada subred; cámbialo si el campo en var.subredes tiene otro nombre.
  availability_zone       = each.value.az # Zona de disponibilidad de cada subred; cámbialo si el campo en var.subredes tiene otro nombre.
  map_public_ip_on_launch = each.value.publica # Asigna IP pública automática según var.subredes; cámbialo si el campo o regla cambia.

  tags = merge(local.common_tags, { Name = "subnet-${each.key}" }) # Nombre y tags de cada subred; cámbialo si la pauta pide otro nombre.
} # Cierra aws_subnet.main.

resource "aws_route_table" "publica" { # Tabla de rutas pública; cámbiala si la pauta exige rutas o tablas distintas.
  vpc_id = aws_vpc.main.id # VPC de la tabla de rutas; cámbialo si apunta a otra VPC.
  route { # Regla de enrutamiento hacia internet; cámbiala si cambian destinos o gateways.
    cidr_block = "0.0.0.0/0" # Todo el tráfico IPv4 externo; cámbialo si se restringe el CIDR.
    gateway_id = aws_internet_gateway.igw.id # Envía el tráfico al IGW; cámbialo si usas otro gateway.
  } # Cierra route.
  tags = merge(local.common_tags, { Name = "rt-publica" }) # Nombre y tags de la tabla de rutas; cámbialo si la pauta pide otro nombre.
} # Cierra aws_route_table.publica.

resource "aws_route_table_association" "publica" { # Asocia subredes públicas a la tabla pública; ajusta si cambia la lógica de asociación.
  for_each       = { for k, v in var.subredes : k => v if v.publica } # Filtra subredes marcadas como públicas; cámbialo si el campo o condición cambia.
  subnet_id      = aws_subnet.main[each.key].id # ID de la subred asociada; cámbialo si cambia el recurso de subred.
  route_table_id = aws_route_table.publica.id # ID de la route table pública; cámbialo si usas otra tabla.
} # Cierra aws_route_table_association.publica.

# --- SECURITY GROUPS --- # Sección de firewalls/security groups; ajusta puertos, orígenes o nombres según la pauta.
resource "aws_security_group" "web" { # Security group para capa web/NLB; cámbialo si cambian las reglas o el nombre del recurso.
  name   = "web-sg${var.ambiente}" # Nombre del SG web en AWS; cámbialo si la pauta pide otro formato de nombre.
  vpc_id = aws_vpc.main.id # VPC del SG web; cámbialo si usas otra VPC.

  ingress { # Regla de entrada HTTP; cámbiala si cambian los puertos o se exige HTTPS (443).
    from_port   = 80 # Puerto inicial 80 (HTTP); cámbialo si la aplicación escucha en otro puerto.
    to_port     = 80 # Puerto final 80 (HTTP); cámbialo si la aplicación escucha en otro puerto.
    protocol    = "tcp" # Protocolo TCP; cámbialo si la evaluación exige otro protocolo.
    cidr_blocks = ["0.0.0.0/0"] # Abierto a cualquier IP; restríngelo si la pauta pide una IP o CIDR específico.
  } # Cierra ingress HTTP.
  ingress { # Regla de entrada SSH; quítala o restríngela si la pauta prohíbe SSH abierto o usa SSM.
    from_port   = 22 # Puerto inicial 22 (SSH); cámbialo si usan otro puerto o método de acceso.
    to_port     = 22 # Puerto final 22 (SSH); cámbialo si usan otro puerto o método de acceso.
    protocol    = "tcp" # Protocolo TCP; cámbialo si corresponde.
    cidr_blocks = ["0.0.0.0/0"] # Abierto a todo internet; cámbialo por tu IP/CIDR si la evaluación exige restringir SSH.
  } # Cierra ingress SSH.
  egress { # Regla de salida general; cámbiala si la evaluación exige egresos restringidos.
    from_port   = 0 # Todos los puertos de salida (inicio); cámbialo si restringen puertos.
    to_port     = 0 # Todos los puertos de salida (fin); cámbialo si restringen puertos.
    protocol    = "-1" # Todos los protocolos; cámbialo si restringen protocolos.
    cidr_blocks = ["0.0.0.0/0"] # Salida hacia cualquier destino; cámbialo si piden limitar egresos.
  } # Cierra egress.
  tags = merge(local.common_tags, { Name = "sg-web" }) # Nombre y tags del SG web; cámbialo si la pauta pide otro nombre.
} # Cierra aws_security_group.web.

resource "aws_security_group" "rds" { # Security group para base de datos RDS; cámbialo si cambia el motor o reglas.
  name   = "rds-sg${var.ambiente}" # Nombre del SG de RDS en AWS; cámbialo si la pauta pide otro formato de nombre.
  vpc_id = aws_vpc.main.id # VPC del SG de RDS; cámbialo si usas otra VPC.

  ingress { # Regla de entrada a la base de datos; cámbiala si cambia el puerto o el origen permitido.
    from_port       = 3306 # Puerto por defecto de MySQL; cámbialo si cambian a PostgreSQL (5432) u otro motor.
    to_port         = 3306 # Puerto final 3306; cámbialo si cambia el puerto de la BD.
    protocol        = "tcp" # Protocolo TCP; cámbialo si corresponde.
    security_groups = [aws_security_group.web.id] # Permite tráfico desde el SG web; cámbialo si otra fuente o CIDR debe conectarse.
  } # Cierra ingress RDS.
  tags = merge(local.common_tags, { Name = "sg-rds" }) # Nombre y tags del SG de RDS; cámbialo si la pauta pide otro nombre.
} # Cierra aws_security_group.rds.

# --- SERVIDORES EC2 --- # Sección de instancias EC2; ajusta según cantidad, tamaño, software o disco pedidos.
resource "aws_instance" "servidores" { # Crea instancias EC2 desde var.servidores; cámbialo si se crea una sola instancia o distinto recurso.
  for_each               = var.servidores # Mapa de servidores de entrada; cámbialo si la variable tiene otro nombre.
  ami                    = data.aws_ami.linux.id # AMI obtenida en el bloque data; cámbialo si usan otra AMI o variable.
  instance_type          = each.value.instance_type # Tipo de instancia EC2; cámbialo si el atributo en var.servidores se llama distinto o es fijo.
  subnet_id              = aws_subnet.main[each.value.subred].id # Subred asignada a cada instancia; cámbialo si el campo o subred cambia.
  vpc_security_group_ids = [aws_security_group.web.id] # Security groups de la instancia; cámbialo si agregan otro SG o cambian el nombre.

  user_data = <<-EOF # Script inicial al arrancar la instancia; cámbialo si la evaluación pide instalar otros paquetes o contenido.
              #!/bin/bash # Intérprete bash para Amazon Linux; cámbialo si usas otro sistema operativo.
              dnf install -y httpd mariadb105 # Instala Apache y cliente MariaDB; cámbialo si piden Nginx, otro servidor o paquetes.
              systemctl start httpd # Inicia el servicio web; cámbialo si piden enable/start de otro servicio.
              echo "Servidor: ${each.key} | Ambiente: ${var.ambiente}" > /var/www/html/index.html # Página de prueba; cámbiala si la evaluación exige otro contenido o ruta.
              EOF # Fin del bloque user_data.

  root_block_device { # Configuración del disco raíz EBS; cámbiala si la evaluación pide otro tamaño o tipo de volumen.
    volume_size = var.ambiente == "prod" ? each.value.disk_size * 2 : each.value.disk_size # Duplica el disco en prod; cámbialo si la pauta pide otro cálculo o tamaño fijo.
  } # Cierra root_block_device.

  tags = merge(local.common_tags, { Name = each.key }) # Nombre y tags de cada EC2; cámbialo si la pauta exige otro formato de Name.
} # Cierra aws_instance.servidores.

# --- NETWORK LOAD BALANCER --- # Sección del balanceador de carga; cámbiala si la pauta pide ALB en vez de NLB o ajustes distintos.
resource "aws_lb" "nlb" { # Crea un Network Load Balancer; cámbialo si piden Application Load Balancer (application).
  name               = "nlb-${var.proyecto}-${var.ambiente}" # Nombre del NLB; cámbialo si la pauta exige otra convención de nombres.
  internal           = false # NLB público (internet-facing); cámbialo a true si la evaluación pide balanceador interno.
  load_balancer_type = "network" # Tipo network (NLB); cámbialo a "application" solo si cambian a ALB.
  subnets            = local.subredes_publicas # Subredes donde vive el NLB; cámbialo si usan subredes privadas o específicas.
  security_groups    = [aws_security_group.web.id] # SG asignado al NLB; cámbialo si la pauta pide un SG exclusivo para el balanceador.
  tags               = merge(local.common_tags, { Name = "nlb-biblioteca" }) # Nombre y tags del NLB; cámbialo si la pauta pide otro nombre o variable.
} # Cierra aws_lb.nlb.

resource "aws_lb_target_group" "tg" { # Target group del NLB; cámbialo si cambian puerto, protocolo o tipo de target.
  name     = "tg-${var.proyecto}-${var.ambiente}" # Nombre del target group; cámbialo si la pauta exige otro nombre.
  port     = 80 # Puerto al que envía tráfico el target group; cámbialo si la app escucha en otro puerto.
  protocol = "TCP" # Protocolo del target group; cámbialo si usan HTTP/HTTPS u otro protocolo.
  vpc_id   = aws_vpc.main.id # VPC del target group; cámbialo si usas otra VPC.
} # Cierra aws_lb_target_group.tg.

resource "aws_lb_listener" "tcp" { # Listener del balanceador; cámbialo si cambian puerto o protocolo (por ejemplo 443).
  load_balancer_arn = aws_lb.nlb.arn # ARN del NLB al que se adjunta; cámbialo si cambia el recurso del LB.
  port              = 80 # Puerto en el que escucha el balanceador; cámbialo si la pauta pide otro puerto.
  protocol          = "TCP" # Protocolo del listener; cámbialo si la evaluación exige otro protocolo.
  default_action { # Acción por defecto del listener; cámbiala si piden otro comportamiento.
    type             = "forward" # Reenvía el tráfico al target group; cámbialo si la pauta pide otra acción.
    target_group_arn = aws_lb_target_group.tg.arn # Target group destino; cámbialo si apunta a otro target group.
  } # Cierra default_action.
} # Cierra aws_lb_listener.tcp.

resource "aws_lb_target_group_attachment" "targets" { # Registra las EC2 en el target group; ajusta si cambian instancias o puerto.
  for_each         = aws_instance.servidores # Itera sobre todas las instancias EC2 creadas; cámbialo si registran otros recursos.
  target_group_arn = aws_lb_target_group.tg.arn # ARN del target group; cámbialo si usas otro target group.
  target_id        = each.value.id # ID de la instancia EC2; cámbialo si el target es IP u otro recurso.
  port             = 80 # Puerto de destino en la instancia; cámbialo si cambia el puerto de la app.
} # Cierra aws_lb_target_group_attachment.targets.

# --- BASE DE DATOS RDS --- # Sección de base de datos relacional; ajusta motor, tamaño, nombre o alta disponibilidad según pauta.
resource "aws_db_subnet_group" "rds" { # Grupo de subredes para RDS; cámbialo si cambia el nombre o subredes de BD.
  name       = "sng-rds-${var.ambiente}" # Nombre del DB subnet group; cámbialo si la pauta exige otro nombre.
  subnet_ids = local.subredes_privadas # Subredes privadas para la BD; cámbialo si la evaluación pide otras subredes.
  tags       = merge(local.common_tags, { Name = "sng-rds" }) # Nombre y tags del subnet group; cámbialo si la pauta pide otro nombre.
} # Cierra aws_db_subnet_group.rds.

resource "aws_db_instance" "mysql" { # Instancia de base de datos RDS; cámbiala si piden clúster Aurora u otro motor.
  identifier             = "db-${var.proyecto}-${var.ambiente}" # Identificador único de la instancia RDS; cámbialo si la pauta exige otro nombre.
  engine                 = "mysql" # Motor de base de datos; cámbialo si piden postgres, mariadb, etc.
  instance_class         = local.clase_rds # Tamaño de instancia RDS; cámbialo si usas clase fija o variable directa.
  allocated_storage      = 20 # Almacenamiento inicial en GB; cámbialo si la evaluación pide otro tamaño o variable.
  db_name                = "bibliotecadb" # Nombre inicial de la base de datos; cámbialo si la evaluación exige otro nombre o variable.
  username               = "admin" # Usuario maestro de la BD; cámbialo si la pauta pide otro usuario o variable.
  password               = var.db_password # Contraseña maestra desde variable; cámbiala si la variable tiene otro nombre.
  db_subnet_group_name   = aws_db_subnet_group.rds.name # Subnet group asociado a RDS; cámbialo si cambia el nombre del recurso.
  vpc_security_group_ids = [aws_security_group.rds.id] # Security group de RDS; cámbialo si cambia el SG o agregan otro.
  publicly_accessible    = false # BD privada sin IP pública; cámbialo a true solo si la evaluación lo pide explícitamente.
  skip_final_snapshot    = true # Omite snapshot final al destruir; cámbialo a false si la pauta exige snapshot final.

  multi_az = var.ambiente == "prod" ? true : false # Multi-AZ solo en prod; cámbialo si la pauta exige siempre true/false o otra regla.

  tags = merge(local.common_tags, { Name = "rds-biblioteca" }) # Nombre y tags de la instancia RDS; cámbialo si la pauta pide otro nombre.
} # Cierra aws_db_instance.mysql.

# --- BUCKET S3 --- # Sección de almacenamiento de objetos S3; ajusta nombre, versionado o reglas según la pauta.
resource "aws_s3_bucket" "bucket" { # Crea el bucket S3; cámbialo si se crean múltiples buckets o cambia el recurso.
  bucket        = format("%s-%s-%s-2026-dv2026", var.proyecto, var.aplicacion, var.ambiente) # Nombre global del bucket; cámbialo si la pauta exige otro patrón o sufijo.
  force_destroy = true # Permite borrar el bucket aunque tenga objetos; cámbialo a false si la evaluación exige proteger datos.
  tags          = merge(local.common_tags, { Name = "bucket-biblioteca" }) # Nombre y tags del bucket; cámbialo si la pauta pide otro nombre.
} # Cierra aws_s3_bucket.bucket.

resource "aws_s3_bucket_versioning" "versioning" { # Configura el versionado del bucket S3; cámbialo si la pauta exige otra regla.
  bucket = aws_s3_bucket.bucket.id # ID del bucket S3; cámbialo si apunta a otro bucket.
  versioning_configuration { # Estado de versionado; cámbialo si se pide habilitarlo o suspenderlo en otros casos.
    status = var.ambiente == "prod" ? "Enabled" : "Suspended" # Habilitado en prod y suspendido en otros; cámbialo si la pauta pide otro comportamiento.
  } # Cierra versioning_configuration.
} # Cierra aws_s3_bucket_versioning.versioning.