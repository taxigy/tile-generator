require 'fog'

connection = Fog::Storage.new({
  provider: 'AWS',
  aws_access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
  aws_secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'),
  region: ENV.fetch('AWS_REGION'),
})

$bucket = connection.directories.get(ENV.fetch('S3_BUCKET_NAME'))

def upload(src, dst)
  puts "upload: #{src} to #{dst}"
  file = $bucket.files.create(
    key: dst,
    body: File.open(src),
    public: true,
  )
end
