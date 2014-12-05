CREATE TABLE parts_i18n (
  pid varchar(3),
  lang varchar(2),
  name varchar(20),
  color varchar(10),
  primary key (pid, lang)
);

INSERT INTO parts_i18n (pid, lang, name, color) VALUES
  ('P1', 'en', 'Nut', 'Red'),
  ('P2', 'en', 'Bolt', 'Green'),
  ('P3', 'en', 'Screw', 'Blue'),
  ('P4', 'en', 'Screw', 'Red'),
  ('P5', 'en', 'Cam', 'Blue'),
  ('P6', 'en', 'Cog', 'Red'),
  ('P1', 'fr', 'Ecrou', 'Rouge'),
  ('P2', 'fr', 'Boulon', 'Vert'),
  ('P3', 'fr', 'Vis', 'Bleu'),
  ('P4', 'fr', 'Vis', 'Rouge'),
  ('P5', 'fr', 'Came', 'Bleu'),
  ('P6', 'fr', 'Rouage', 'Rouge');
