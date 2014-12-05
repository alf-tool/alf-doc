CREATE TABLE colors (
  color CHAR(15) NOT NULL,
  lang CHAR(2) NOT NULL,
  label CHAR(15) NOT NULL,
  PRIMARY KEY (color, lang)
);

INSERT INTO colors (color, lang, label) VALUES
  ('Red', 'en', 'Red'),
  ('Red', 'fr', 'Rouge'),
  ('Green', 'en', 'Green'),
  ('Green', 'fr', 'Vert'),
  ('Blue', 'en', 'Blue'),
  ('Blue', 'fr', 'Bleu');