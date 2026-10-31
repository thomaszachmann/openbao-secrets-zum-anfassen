# Audit-Device deklarativ: per API lässt OpenBao 2.x das nicht mehr zu
audit "file" "stdout" {
  options {
    file_path = "stdout"
  }
}
