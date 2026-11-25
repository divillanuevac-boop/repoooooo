output "nlb_dns_name" { # Nombre del output para el DNS del NLB; cámbialo si la evaluación exige otro nombre de output.
  value = aws_lb.nlb.dns_name # Valor exportado (DNS público del NLB); cámbialo si cambia el recurso del LB o el atributo pedido (por ejemplo arn o zone_id).
} # Cierra output "nlb_dns_name".

output "rds_endpoint" { # Nombre del output para el endpoint de RDS; cámbialo si la evaluación exige otro nombre de output.
  value = aws_db_instance.mysql.endpoint # Valor exportado (host:puerto de la instancia RDS); cámbialo si cambia el recurso RDS o piden address, port o arn.
} # Cierra output "rds_endpoint".

output "s3_bucket_name" { # Nombre del output para el bucket S3; cámbialo si la evaluación exige otro nombre de output.
  value = aws_s3_bucket.bucket.id # Valor exportado (nombre/ID del bucket S3); cámbialo si cambia el recurso de S3 o piden arn o bucket_domain_name.
} # Cierra output "s3_bucket_name".