
-- This file is generated by the DataFiller free software.
-- This software comes without any warranty whatsoever.
-- Use at your own risk. Beware, this script may destroy your data!
-- License is GPLv3, see http://www.gnu.org/copyleft/gpl.html
-- Get latest version from http://www.coelho.net/datafiller.html

-- Data generated by: /usr/local/bin/datafiller
-- Version 2.0.1-dev (r832 on 2015-11-01)
-- For postgresql on 2017-05-03T12:34:39.879063 (UTC)
--
-- fill table data.user (2)
\echo # filling table data.user (2)
COPY data.user (id,name,email,"password") FROM STDIN (FREEZE ON);
1	alice	alice@email.com	pass
2	bob	bob@email.com	pass
\.
--
-- restart sequences
ALTER SEQUENCE data.user_id_seq RESTART WITH 3;
--
-- analyze modified tables
ANALYZE data.user;

insert into data.recipe (title, description, instructions, tags, portions, ingredients) values
('Cheese Cake',
  'Väldigt god cheese cake, servera gärna med färska bär till.',
  '1. Smält smöret. Krossa kexen grovt i en matberedare. Häll i smöret och kör till en smulig smet.
2. Tryck ut blandningen i en bakform med löstagbar kant. Du behöver inte trycka upp smeten längs kanterna. Det ska bara bli en bottenplatta. Ställ kallt. Värm ugnen till 175 grader.
3. Rör ihop philadelphiaosten med sockret och vaniljsockret i en bunke. Blanda ner vetemjölet och saltet och rör till en slät smet.
Rör ner äggen – ett i taget – så att de blandas ut ordentligt i smeten.
Riv citronskal och pressa i lite citronsaft – smaka av till lagom nivå.
4. Häll i formen med kexbotten. Grädda i nedre delen av ugnen i cirka 45-50 minuter*.
5. Kakan kommer att verka mjuk men den stelnar när den svalnar.
Låt kakan kallna helt och lossa den sedan från formen med en kniv eller liten spatel. Hur lång tid kakan ska gräddas varierar från ugn till ugn och beroende på form. Tiden ska ses som ungefärlig.

[source](recept.axellarsson.nu)',
  '{"efterrätt"}',
  12,
  '{
    "botten": [
      "12 st digestivekex",
    "75 g smör"
    ],
    "fyllningen": [
      "800 g philedphiaost",
    "2 dl strösocker",
    "1 msk vaniljsocker",
    "2 msk vetemjöl",
    "0,5 tsk salt",
    "4 st ägg",
    "citronskal och citronsaft"
    ]
  }'
),
(
  'Fläskpannkaka i ugn',
  'Fläskpannkaka i ugn lagas på samma smet som till vanliga pannkakor tillsatt med rimmat sidfläskm, men naturligtvis kan man även laga ungspannkaka på enbart pannkakssmet och då servera den som efterrätt. Ugnspannkaka serveras ofta som ensamrätt med lingongsylt.',
  'Förberedelser:
- Knäck äggen och vispa upp dem lätt i bunken. Tillsätt mjölken och vetemjölet. Arbeta samman en jämn pannkakssmet. Skär det rimmade fläsket i tärningar.

Tillagning:

- Bryn fläsket i lång- eller stekpanna.
- Blanda det stekta fläsket med smeten och häll blandningen över stekfettet i pannan.
- Grädda i ugn 225 grader, 20-25 minuter. Om ni kör flera fläskpannkakor samtidigt, använd 3D varmluft på 200 grader. Låt pannkakan svalna 2-3 minuter och servera den sedan direkt ur formen, skuren i bitar med lingonsylt som enda tillbehör.
',
  '{"vardagsmat"}',
  4,
  '{
    "ingredienser": [
      "6 dl mjölk",
      "200 - 300 g rimmat fläsk",
      "3 ägg",
      "2,5 dl mjölk"
    ],
    "tillbehör": [
      "rårörda lingon"
    ]
  }'

),
(
  'Omelett',
  'En omelett kan även den som har kökstummen mitt i handen laga och det tar bara 10 minuter! Krydda till exempel med paprikapulver och chili om du vill ha lite mer smak på omeletten. ',
  '- Vispa ihop ägg, mjölk, salt och peppar lätt, så att allt precis bara blandas.
- Hetta upp en stekpanna och låt matfettet fräsa så att det får en aning färg.
- Häll i omelettsmeten. Rör med en gaffel så att lös smet kan rinna ner mot bottnen. Omeletten är klar när den fortfarande är krämig på ytan och har släppt i kanterna. Vik omeletten dubbel och servera.
',
  '{"frukost"}',
  4,
  '{
    "ingredienser": [
      "6 ägg",
      "1 dl mjölk",
      "salt och peppar",
      "2 msk smör"
    ]  }'

),
(
  'Iskaffe med kondenserad mjölk och choklad',
  'Gör en svalkande och söt iskaffe med smak av choklad! Kallbryggt kaffe med kakao, kondenserad mjölk och vanlig mjölk blir en läskande iced mocha kaffe, perfekt när du behöver en koffeinkick under soliga dagar.',
  '## Dag 1: Blanda kaffet med vatten och kakaon i en burk. Rör runt och sätt på ett lock. Låt stå i rumstemperatur ca 1 dygn.
## Dag 2: Sila genom ett kaffefilter eller en silduk.
- [ ] Blanda med vatten.
- [ ] Häll upp i fyra glas med mycket is. Blanda kondenserad mjölk och mjölk och häll i glasen.
',
  '{"drink"}',
  4,
  '{
    "dag 1": [
      "1 dl malet kaffe",
      "4 dl vatten",
      "2 msk kakao"
    ],
    "dag 2": [
      "3 dl vatten",
      "1 1/2 dl kondenserad mjölk",
      "3 dl mjölk",
      "is"
    ]}'
),
(
  'Rabarberlemonad',
  'Rabarberlemonad är en syrlig, söt och somrig dryck som passar lika bra i picknickkorgen som till fördrink. Den hemmagjorda rabarberlemonaden blir extra god med färskpressad citronjuice och strösocker. Välj gärna en röd rabarbersort för färgens skull. ',
  '- [ ] Skiva rabarbern. Lägg i en kastrull med socker och hälften av vattnet. Låt koka 5–10 minuter. Låt svalna.
  - [ ] Sila genom en silduk eller finmaskig sil. Blanda med resten av vattnet (kallt), citronjuice och is i en stor kanna.
  ',
  '{"drink"}',
  4,
  '{
    "ingredienser": [
      "200 g rabarber",
      "1 dl strösocker",
      "12 dl vatten",
      "1 1/2 dl färskpressad citronjuice",
      "is till servering"
    ]
   }'
);
