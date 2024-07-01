class MinioToIP {
  static String replaceMinioWithIP(String url, String ipAddress) {
    return url.replaceAll("http://minio:9000", "http://$ipAddress:9000");
  }
}