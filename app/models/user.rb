class User < ActiveRecord::Base
  attr_accessible :name, :high_score
  #follow an user
  def follow! user
    $redis.multi do
      $redis.sadd self.redis_key(:following), user.id
      $redis.sadd user.redis_key(:followers), self.id
    end
  end
  
  #unfollow an user
  def unfollow! user
    $redis.multi do
      $redis.srem self.redis_key(:folllowing), user.id
      $redis.srem user.redis_key(:followers), self.id
    end
  end

  #users that self follows
  def following
    user_ids = $redis.smembers self.redis_key :following
    User.where id: user_ids
  end
  
  #users that follow self
  def followers
    user_ids = $redis.smembers self.redis_key :followers
    User.where id: user_ids
  end

  #user who follow and are being followed by self
  def friends
    user_ids = $redis.sinter(self.redis_key(:following), self.redis_key(:followers))
    User.where id: user_ids
  end
  
  #does the user follow self
  def followed_by? user
    $redis.sismember self.redis_key(:followers), user.id
  end

  # does self follow user
  def following? user
    $redis.sismember self.redis_key(:following), user.id
  end

  #number of followers
  def followers_count
    $redis.scard self.redis_key :followers
  end

  #number of users being followed
  def following_count
    $redis.scard self.redis_key :following
  end

  #helper method to generate redis key
  def redis_key str
    "user:#{self.id}:#{str}"
  end

  #log high score
  def scored score
    if score > self.high_score
      $redis.zadd "highscores", score, self.id
    end
  end

  #table rank
  def rank
    $redis.zrevrank("highscores", self.id) + 1
  end

  #high score
  def high_score
    $redis.zscore("highscores", self.id).to_i
  end

  #load top 3 users
  def self.top_3
    $redis.zrevrange("highscores", 0, 2).map { |id| User.find(id)}
  end
end
