config = YAML.load_file(Rails.root + 'config' + 'mongodb.yml')
MongoMapper.setup(config, Rails.env, { :logger => Rails.logger })
