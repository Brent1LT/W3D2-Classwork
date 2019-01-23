require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database 
  include Singleton
  
  def initialize 
    super('questions.db')
    self.type_translation = true 
    self.results_as_hash = true 
  end 
end 

class User
  attr_accessor :id, :fname, :lname

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM users")
    data.map { |datum| User.new(datum) }
  end 

  def self.find_by_id(id)
    query = <<-SQL
      SELECT 
        *
      FROM 
        users
      WHERE
        id = ?
      SQL
    user = QuestionsDatabase.instance.execute(query, id)
    

    return nil unless user.length > 0 
    User.new(user.first)
  end 

  def self.find_by_name(fname, lname)
    name = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
    SELECT
      *
    FROM
      users
    WHERE
      fname = ? AND lname = ?
    SQL

    return nil unless name.length > 0 
    User.new(name.first)
  end

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end 

  def authored_questions
    Question.find_by_author_id(self.id)
  end
  
  def authored_replies
    Reply.find_by_user_id(self.id)
  end 

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(self.id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(self.id)
  end 

end 

class Question
  attr_accessor :id, :title, :body, :author_id


  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
    data.map { |datum| Question.new(datum) }
  end 

  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
       *
      FROM 
      questions
      WHERE
      id = ?
    SQL

    return nil unless question.length > 0 
    Question.new(question.first)
  end 

  def self.find_by_author_id(author_id)
    author_questions = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?
      SQL

      return nil unless author_questions.length > 0 
      author_questions.map {|author| Question.new(author) }
  end 

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end 

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end 

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end 

  def author
    User.find_by_id(self.author_id)
  end
  
  def replies
    Reply.find_by_question_id(self.id)
  end 

  def followers
    QuestionFollow.followers_for_question_id(self.id)
  end 

  def num_likes
    QuestionLike.num_likes_for_question_id(self.id)
  end 

  def likers
    QuestionLike.likers_for_question_id(self.id)
  end 
end

class QuestionFollow
  attr_accessor :id, :question_id, :user_id


  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM question_follows")
    data.map { |datum| QuestionFollow.new(datum) }
  end 

  def self.followers_for_question_id(question_id)
    followers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT 
        *
      FROM
        users
      JOIN 
        question_follows ON users.id = question_follows.user_id
      WHERE 
        question_follows.question_id = ?  
    SQL

    return nil unless followers.length > 0
    followers.map {|user| User.new(user)}
  end 

  def self.followed_questions_for_user_id(user_id)
    questions_followed = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT 
        *
      FROM
        questions
      JOIN
        question_follows ON questions.id = question_follows.question_id
      WHERE
        question_follows.user_id = ?
    SQL

    return nil unless questions_followed.length > 0
    questions_followed.map { |questions| Question.new(questions)}
  end 

  def self.find_by_id(id)
    question_follow = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
       *
      FROM 
      question_follows
      WHERE
      id = ?
    SQL

    return nil unless question_follow.length > 0 
    QuestionFollow.new(question_follow.first)
  end     

  def self.most_followed_questions(n)
    most_followed = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT 
        *
      FROM 
        questions
      JOIN
        question_follows ON questions.id = question_follows.question_id
      GROUP BY 
        question_id
      ORDER BY
        COUNT(question_id) DESC
      LIMIT ?
    SQL

    most_followed.map {|question| Question.new(question)}
  end 

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end 
end

class Reply
  attr_accessor :id, :question_id, :user_id, :parent_id, :body


  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM replies")
    data.map { |datum| Reply.new(datum) }
  end 

  def self.find_by_id(id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
       *
      FROM 
      replies
      WHERE
      id = ?
    SQL

    return nil unless reply.length > 0 
    Reply.new(reply.first)
  end 

  def self.find_by_user_id(user_id)
    user_replies = QuestionsDatabase.instance.execute(<<-SQL, user_id)

    SELECT
      *
    FROM
      replies
    WHERE
      user_id = ?
    SQL

    return nil unless user_replies.length > 0 
    user_replies.map {|reply| Reply.new(reply)}
  end
  
  def self.find_by_question_id(question_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      *
    FROM
      replies
    WHERE
      question_id = ?
    SQL

    return nil unless replies.length > 0 
    replies.map {|reply| Reply.new(reply)}
  end 

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
    @parent_id = options['parent_id']
    @body = options['body']
  end 

  def author
    User.find_by_id(self.user_id)
  end 

  def question
    Question.find_by_id(self.question_id)
  end 

  def child_replies
    Reply.find_by_id(self.parent_id)
  end 

  def parent_reply
    child = QuestionsDatabase.instance.execute(<<-SQL, self.id)
    SELECT
      *
    FROM
      replies
    WHERE
      parent_id = ?
    SQL

    return nil unless child.length > 0
    child.map { |child| Reply.new(child)}
  end 
end

class QuestionLike
  attr_accessor :id, :user_id, :question_id, :num_of_likes


  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM question_likes")
    data.map { |datum| QuestionLike.new(datum) }
  end 

  def self.find_by_id(id)
    question_like = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
       *
      FROM 
      question_likes
      WHERE
      id = ?
    SQL

    return nil unless question_like.length > 0 
    QuestionLike.new(question_like.first)
  end 

  def self.likers_for_question_id(question_id)
    likers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        users
      JOIN
        question_likes ON users.id = question_likes.user_id
      WHERE
        question_id = ?
    SQL

    likers.map {|liker| User.new(liker)}
  end 

  def self.num_likes_for_question_id(question_id)
    num = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        num_of_likes
      FROM
      question_likes
      WHERE 
        question_id = ?
    SQL
    number = QuestionLike.new(num.first)
    number.num_of_likes
  end 

  def self.liked_questions_for_user_id(user_id)
    liked = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      *
    FROM
      questions
    JOIN
      question_likes ON questions.id = question_likes.question_id
    WHERE
      user_id = ?
    SQL

    return nil unless liked.length > 0
    liked.map { |question| Question.new(question)}
  end

  def self.most_liked_questions(n)
    most_liked = QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT
      *
    FROM
      questions
    JOIN
      question_likes ON question_likes.question_id = questions.id
    GROUP BY
      question_id
    ORDER BY
      num_of_likes DESC
    LIMIT ?
    SQL

    most_liked.map { |liked| Question.new(liked)}

  end 

  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
    @num_of_likes = options['num_of_likes']
  end 
end