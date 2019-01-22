PRAGMA foreign_keys = ON;

-- DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL, 
  body TEXT NOT NULL,
  author_id TEXT NOT NULL,

  FOREIGN KEY (author_id) REFERENCES users(id) 
);

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,

  FOREIGN KEY (question_id)  REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  parent_id INTEGER,
  body TEXT NOT NULL,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY, 
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  num_of_likes INTEGER,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
  users (fname, lname)
VALUES
  ('Steph', 'Curry'),
  ('Draymond', 'Green'),
  ('Klay', 'Thompson'),
  ('Kevin', 'Durant'),
  ('Lebron', 'James');

INSERT INTO
  questions (title, body, author_id)
VALUES
  ('Food', 'What''s the best Italian restaurant?', (SELECT id FROM users WHERE fname = 'Kevin') ),
  ('Education', 'What''s the best college in California?', (SELECT id FROM users WHERE fname = 'Steph') ),
  ('Food', 'How dangerous is gas station sushi?', (SELECT id FROM users WHERE fname = 'Lebron') ),
  ('Exercise', 'How much can you bench bro?', (SELECT id FROM users WHERE fname = 'Draymond') );

INSERT INTO
  question_follows (question_id, user_id)
VALUES
  (2, 5),
  (3, 4),
  (1, 2),
  (4, 2),
  (3, 1);

INSERT INTO
  replies (question_id, user_id, parent_id, body)
VALUES
  (1, 2, NULL, 'Olive Garden'),
  (4, 3, NULL, 'more than you'),
  (4, 2, 2, 'try me');

INSERT INTO
  question_likes (user_id, question_id, num_of_likes)
VALUES
  (2, 4, 2),
  (1, 3, 1),
  (3, 2, 1);

    