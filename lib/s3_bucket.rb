require 'aws-sdk'

region = ENV.fetch('AWS_REGION')
bucket_name = ENV.fetch('S3_BUCKET_NAME')

s3 = Aws::S3::Resource.new(region: region)
$bucket = s3.bucket(bucket_name)

def s3_upload(src, dst)
  puts "upload: #{src} to #{dst}"
  obj = $bucket.object(dst)
  obj.upload_file(src)
end

def s3_delete_dir(name)
  objs = $bucket.objects(prefix: "#{name}/").map { |item| { key: item.key } }
  if objs.any?
    $bucket.delete_objects({
      delete: {
        objects: objs,
        quiet: false,
      },
    })
  end
end
