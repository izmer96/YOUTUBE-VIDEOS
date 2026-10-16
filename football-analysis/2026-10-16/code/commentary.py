"""Analyst-written counterarguments and assessments for the master-ranking selections.
Every factual claim below is taken from the Sofascore-derived dataset for this report (current season to 15 Oct 2026)."""

C = {
'Manchester City|home': dict(
 counter="City's home defence is the weak point: 8 goals conceded in 5 home games (1.52 xGA per home game), including a 2-4 home defeat to PSG six days before this match. AEK's strong record (8-4-1, 34-9) was built against a very weak schedule (average opponent strength 0.58 vs City's 2.09), so there are no genuinely comparable AEK results to test the rating. City also sit between Ipswich (Sat) and Aston Villa (Sat), so rotation is likely.",
 assessment="Highest single probability on the slate. My model has it at 77% and the de-vigged market at 90%; that 13-point gap is why reliability is Low even though every source makes City heavy favourites. AEK's only league-phase test against a decent non-Greek side ended in a 1-3 defeat at Shakhtar."),
'FC Bayern München|o25': dict(
 counter="Bayern keep clean sheets at home (2 of 3) and Leipzig's games this season are lopsided (BTTS only 25%), so a 2-0 or 3-0 is possible. The most recent head-to-head at the Allianz (Feb 2026) finished 2-0. Neuer is doubtful, Musiala is out, and Bayern host Arsenal four days later, which could encourage game management once they lead.",
 assessment="The most robust totals selection: model 79%, market 83%, no reliability flags. Bayern average 3.34 xG per match and have gone over 2.5 in 8 of 9 matches (3 of 3 at home, 17-1 aggregate). Leipzig have gone over in 6 of 8, and four of the last five meetings produced 6 goals."),
'AS Roma|home': dict(
 counter="Roma are missing goalkeeper Svilar (75% of minutes) and Cristante (71%), and Koné is doubtful; the model already cuts Roma's attack by 6% and raises Slovan's by 7% for this. Roma's recent form has cooled (1-3-1 over the last five, xG 1.30 for / 1.61 against), they lost 3-4 at home to Real Madrid in the Champions League, and they visit Napoli four days later.",
 assessment="Model (81%) and market (82%) agree almost exactly. Slovan's two league-phase matches against stronger sides were a 0-3 home defeat to Stuttgart (xG 0.78-2.19) and a 1-6 loss at PSG (xG 0.76-4.57). They concede 3.38 xG per UEFA match where data exist."),
'Lincoln Red Imps|away': dict(
 counter="Lincoln have pulled off home results against far stronger clubs: they beat Lech Poznań 2-1 in Gibraltar last season and drew 1-1 with Omonia this summer. Twente are 2-4-1 away with BTTS in 86% of away games, and they play at AZ three days later. There is no bookmaker price yet and xG exists for only 5 of Lincoln's 14 matches.",
 assessment="Ranks high because the rating gap is the largest of any UEFA fixture here (model expected goals 0.79 vs 2.80). Reliability is Low: this is a model-only number, Lincoln's data are thin, and their home upsets show they are harder to beat than the rating implies."),
'FC Bayern München|home': dict(
 counter="Bayern have drawn 3 of 9 matches (including 3-3 at Viking despite xG 3.29-0.72). Leipzig are 4-0-0 at home and score 2.88 goals per game. Neuer is doubtful and the Arsenal match follows on Wednesday.",
 assessment="Strongly supported and High reliability: model 74%, market 77%. Leipzig are 1-0-3 away this season, conceding 2.25 goals per away game (xGA 2.07), and Bayern have beaten Leipzig in 4 of the last 5 meetings (5-1, 6-0, 5-1 away, 2-0)."),
'Paris Saint-Germain|o25': dict(
 counter="Elite-versus-elite matches can turn cagey: PSG's comparable games against Bayern last season included a 1-1, and Barcelona beat Real Madrid 2-0 in May. The single most likely score is still 1-1 (7.7%), which is under the line. Barcelona host Real Madrid five days later.",
 assessment="Two of Europe's highest-volume attacks: Barcelona are 10-0-0 with 43 goals (3.53 xG per game, over 2.5 in 9 of 10, 5 of 5 away), and PSG have gone over in 8 of 10 (3 of 3 at home). The model's 71% is below the market's 78%, so reliability is Medium rather than High."),
'Inter|home': dict(
 counter="Lautaro Martínez is out (77% of minutes, 6 goals), the most damaging absence for any favourite in this set; the model trims Inter's attack by 10%. Inter lost both Champions League matches, conceding 3.52 xG per game, and concede 2.0 per home game. Shakhtar are 9-1-1 and drew 1-1 at PSV.",
 assessment="Inter beat every comparable Serie A opponent (Udinese 5-3, Cagliari 1-0, Monza 4-1, Parma 3-0), and Shakhtar's record comes from a weak domestic schedule (average opponent strength 0.51); they lost 1-3 and 1-2 to Crystal Palace last season. The model (69.5%) sits 9 points below the market (78%), hence Medium."),
'Manchester City|home#ips': None,
'FK Jablonec|away': dict(
 counter="Rotation is the main risk. Brighton play at Liverpool three days later and drew 0-0 away at Tromsø in qualifying. Jablonec are strong at home: 6-1-1, 4 goals conceded in 8, clean sheets in 62%. Superbet (66% de-vigged) is clearly less confident than the model (76%).",
 assessment="Brighton have won five in a row (17-2), including 4-0 v Kauno Žalgiris in MD1 (xG 4.02-0.04). Expected goals in the final distribution are 0.90 v 2.32. Medium reliability: the market anchor is a single bookmaker priced six days out, the model-Superbet gap is 10 points, and the result depends on how strong Brighton's XI is."),
'Real Madrid|home': dict(
 counter="Vinícius Júnior is suspended for this league match (81% of minutes, 1 goal 3 assists), so Real's attack is cut by 5%. Real host Leipzig on Wednesday and visit Barcelona next Sunday, so rotation is plausible. Sevilla have scored in every match this season (8 of 8).",
 assessment="Real are 5-0-0 at home (15-3, xG 2.52 for / 1.00 against) and have beaten Sevilla in each of the last four meetings. Sevilla lost 1-3 to both Atlético and Barcelona, their two most comparable opponents, and are without Sierra (78% of minutes) and the suspended Isaac Romero. Model 71.5%, market 76%."),
'Sporting CP|home': dict(
 counter="Sporting are missing Zalazar (67% of minutes, 3 goals 1 assist) and Debast. They draw often (3 in 10, including 2-2 at home to Arouca), and LASK's attack is genuine: 2.79 goals and 3.02 xG per game.",
 assessment="Model and market agree exactly (74%). LASK have lost 4 of their last 5 (7-14), including a 3-6 home defeat to Liverpool, and concede 2.75 goals per UEFA match. Sporting have had 8 days' rest; LASK played four days earlier."),
'Real Madrid|o25': dict(
 counter="Leipzig's away games go over mainly because they concede; their own away xG is only 1.28. If Leipzig fail to score (about a 34% chance in the final distribution), Real must score three. Real's xG has dipped to 1.88 over the last five.",
 assessment="Real have gone over in 8 of 10 (both Champions League games: 2-1 v Inter, 4-3 at Roma). Leipzig have gone over in 6 of 8, and in 3 of 4 away. Model 71%, market 76%, final 75%."),
'Aston Villa|home': dict(
 counter="Villa's domestic form is poor: 1-2-3 in the league with 6 goals in 6 and 1.15 xG per game. Maatsen, Ruggeri and Hemmings are out. Viking scored three against Bayern and average 2.5 goals per game, and Villa face Manchester City three days later.",
 assessment="Villa won both Champions League matches (6-0 v Fenerbahçe, 3-2 at Club Brugge), and Viking concede 2.74 xG per UEFA match; they lost 1-3 at Stuttgart, and their 3-3 with Bayern came despite xG of 0.72-3.29. The model is 7 points below the market, hence Medium."),
'Real Betis|o25': dict(
 counter="Betis home games are low-event: over 2.5 in only 2 of 5 home games, and 3 of 8 in the league. Betis played Porto three days earlier and Barcelona go to PSG three days later, so both may rotate. The model's 67% is 9 points under the market.",
 assessment="Barcelona's away games have all gone over 3.5 (21-4 aggregate, 3.45 xG per away game), and four of the last five meetings went over (5-1, 3-5, 3-1, 2-2)."),
'Real Madrid|home#lei': None,
'Manchester City|o25': dict(
 counter="AEK's away games are low-scoring: over 2.5 in only 2 of 6, with 1.17 goals for and 1.00 against per away game. In the final distribution AEK fail to score about 60% of the time, so City may need three on their own, and they may manage the game with Villa next. The model says 63% against the market's 76%.",
 assessment="City have gone over in 4 of 5 home games, and this season's Champions League league phase is averaging 4.08 goals per match. Reliability is Low because of the 13-point model-market gap."),
'Fenerbahçe|home': dict(
 counter="Fenerbahçe lost 0-6 at Villa three days before this and host Slavia three days after, so fatigue and rotation are real. Alanyaspor are hard to beat (3-3-1, including a 1-0 win over Beşiktaş), and the last meeting at Fenerbahçe ended 2-2. Heavy rain and 9 m/s wind are forecast. The bookmaker margin (12%) suggests a softer market.",
 assessment="Alanyaspor score only 1.14 goals per game (xG 1.20). Fenerbahçe won three of the last four meetings, and the model (68%) and market (72%) are close."),
'Aston Villa|o25': dict(
 counter="Villa's league attack has stalled (1.00 goals and 1.15 xG per game), and Viking's away games are tight: over 3.5 in only 18%, conceding 0.94 per away game.",
 assessment="Both Villa Champions League games went over, Villa have gone over in their last 5 matches, and all four of Viking's UEFA games had 4+ goals (9-9 aggregate). Model and market agree (68% vs 72%)."),
'AS Roma|o25': dict(
 counter="If Slovan fail to score (about a 49% chance in the final distribution), Roma need three. Roma have been tight at home in the league (0.5 goals conceded per league game) and are missing midfield regulars. 2-0 (11%) is the single most likely score. Heavy rain is forecast for Rome (low-confidence forecast six days out).",
 assessment="All four Roma home games went over 2.5. Slovan's two league-phase matches finished 0-3 and 1-6, and they've gone over in 7 of their last 10. The model is 66%, the market 73%."),
'Sabah FK|away': dict(
 counter="Sabah are 8-0-0 at home this season (22-3) and beat Slavia 2-0 in Baku in MD2. Dortmund lost 0-1 at Bodø/Glimt in MD2. The model rates Dortmund at only 59% against the market's 73%, so reliability is Low.",
 assessment="Sabah's win over Slavia came against the run of play (xG 1.35-2.14), and their other test against a top side was a 0-4 loss at Manchester United (xG 0.84-3.54). Dortmund are 6-1-2 with xG 1.80 for / 1.17 against."),
'Inter|o25': dict(
 counter="Shakhtar's away games are low-scoring: over 2.5 in 50%, over 3.5 in 0%, and 0.33 goals conceded per away game. Their comparable trip to PSV ended 1-1 (xG 0.62-0.44). Lautaro's absence lowers Inter's ceiling.",
 assessment="Inter have gone over in 7 of 8, including all 5 home games, and 4 of those 5 had 4+ goals. Model 62%, market 72%."),
'OFI Crete|away': dict(
 counter="OFI are 5-1-0 at home with 2 goals conceded and beat Hoffenheim 2-0 in Heraklion in MD1, a direct example of an upset against Bundesliga opposition. Leverkusen play Hoffenheim three days later.",
 assessment="OFI's chance creation is weak (0.98 xG for, 1.30 against per game). Against better sides they lost 1-2 at Rennes (xG 0.06-1.46) and 0-3 at AEK. Leverkusen are 6-1-1, average 3.2 goals away from home, and won 4-0 at Lech Poznań in MD2 (xG 5.16-0.50). Model (70%) and Superbet (75% de-vigged) agree; Medium reliability because the market anchor is a single bookmaker priced six days out."),
'Lincoln Red Imps|o25': dict(
 counter="Lincoln's matches are low-scoring: over 2.5 in 36% overall and 33% in UEFA ties. Twente's last five went over only once. This selection depends almost entirely on Twente scoring three or more.",
 assessment="Weaker than the Twente win it is correlated with. Model-only and Low reliability; treat it as a byproduct of the large expected-goals gap rather than an independent edge."),
'RC Strasbourg|o25': dict(
 counter="PSG host Barcelona three days later and may rotate. PSG's Ligue 1 output has lagged their chances (1.83 goals vs 2.72 xG per game). Strasbourg are missing Nanasi (70% of minutes) and Doukouré.",
 assessment="Strasbourg have kept no clean sheets in 6 (BTTS 83%, over 2.5 83%), PSG have gone over in 80%, and all four recent meetings went over (4-2, 2-1, 3-3, 1-2). Model 63%, market 72%."),
'Eintracht Frankfurt|o25': dict(
 counter="The sample is only 6 matches for each side. Köln are without six players, including forwards Ache and Dallinga, which cuts their attack by 11%. My model, which shrinks totals heavily toward league norms, gives only 60% against the market's 72%.",
 assessment="Frankfurt's xG for and against (1.87 + 2.44) also points high. Every Frankfurt match has had 4+ goals (6 of 6), they concede 2.67 per game, and Köln have had BTTS in all 6. Low reliability because of the model-market gap and small samples."),
'Sporting CP|o25': dict(
 counter="Sporting are outscoring their xG (2.50 goals vs 1.88 xG per game), and the xG-weighted model gives only 64%. Zalazar's absence removes a goal source.",
 assessment="7 of Sporting's 10 matches had 4+ goals, LASK have gone over 2.5 in 11 of 14, and LASK concede 2.8 per game over their last five."),
'FC Bayern München|btts': dict(
 counter="Bayern have kept clean sheets in 2 of 3 home games, and Leipzig's games are often one-sided (BTTS 25% this season). Leipzig's away xG is only 1.28 per game.",
 assessment="Leipzig have scored in 7 of 8, and Bayern conceded in 6 of 9 overall. The model (66%) and market (69%) agree, with no flags."),
'FC Ararat-Armenia|away': dict(
 counter="AZ's away form is ordinary (3-0-2, failing to score in 40% of away games), and Ararat are 7-2-1 at home. AZ host Twente three days later. Superbet is less confident (63% de-vigged v the model's 69%).",
 assessment="Against comparable opposition Ararat lost 1-4 at home to Sparta Prague and 1-3 at Jagiellonia. AZ create 2.45 xG per game. Medium reliability: the market anchor is a single bookmaker (Superbet.ro)."),
'Eintracht Frankfurt|btts': dict(
 counter="Köln's striker options are depleted (Ache, Dallinga and Rondić all out), so their scoring run could stop. The model has 59% against the market's 71%.",
 assessment="Köln have had BTTS in every match (6 of 6) and kept no clean sheets. Frankfurt have kept 1 clean sheet in 6 and concede 2.44 xG per game."),
"Borussia M'gladbach|btts": dict(
 counter="Gladbach failed to score in 2 of 6 (0-5 at Freiburg, 0-3 at Leipzig). New coach Blessin has had one match, and Kleindienst is doubtful. Hoffenheim played (and lost 2-3 to) Beşiktaş on Thursday.",
 assessment="Gladbach concede 3.0 per game, both their home games ended 3-4, Hoffenheim have had BTTS in every league game, and three of the last four meetings had both teams scoring (4-4, 5-1, 1-2)."),
'Frosinone|btts': dict(
 counter="Frosinone's league games are tighter (BTTS 33%, failed to score in 2 of 6). The model (59%) is 10 points below the market (69%).",
 assessment="Sassuolo have scored in every match (8 of 8) and had BTTS in every league game. Frosinone concede 2.27 xG per game and have scored in 75% of all matches."),
'Real Betis|btts': dict(
 counter="Barcelona kept clean sheets in 4 of 10 (half their league games), and Betis created only 0.93 xG at home to Real Madrid, their most comparable opponent.",
 assessment="Betis have scored in every match this season, Barcelona conceded in 6 of 10, and all of the last five Betis-Barcelona meetings had both teams scoring."),
'Real Betis|o25#fey': None,
'RC Strasbourg|away': dict(
 counter="Strasbourg beat PSG 2-1 in May 2025 and drew 3-3 at the Parc in October 2025. PSG have drawn 2 of their 5 away matches this season, and Barcelona come to Paris on Tuesday.",
 assessment="PSG have won five in a row. Strasbourg concede 2.0 per game (1.84 xGA), and the model and market agree (63% vs 68%)."),
'FK Crvena zvezda|btts': dict(
 counter="Venue-specific records contradict this. Crvena's home games had BTTS in only 22% (clean sheets in 67%), and Copenhagen's away games only 30% (clean sheets in 60%). Osman Bukari is suspended. Superbet prices GG at 1.58 (60% de-vigged), below the model's 66%.",
 assessment="The estimate comes from the two teams' cross-league ratings being nearly equal (model expected goals 1.62 vs 1.72), not from BTTS history. This is a good example of a probability that ranks high but rests on contested evidence."),
}

C.update({
'Real Betis|o25__Feyenoord': dict(
 counter="Betis home games are low-event (over 2.5 in 40%). Feyenoord's 3-2 win over Como came from only 0.59 xG, so their UEFA scoring has been finishing-driven.",
 assessment="Feyenoord have gone over 2.5 and over 3.5 in 8 of 10, and Betis's two UEFA matches both had 4+ goals. The last meeting ended 2-1. Model 62%, market 68%."),
"Borussia M'gladbach|o25": dict(
 counter="A coach in his first home match (Blessin) often prioritises defensive stability, and Hoffenheim rotate between Europa League games.",
 assessment="Every Gladbach match has gone over (6 of 6), Hoffenheim have gone over in 7 of 8, and the last four meetings averaged 5.25 goals."),
'FC Bayern München|o35': dict(
 counter="Over 3.5 needs four goals, and many likely scores sit just below it: 2-1, 3-0 and 2-0 together make up about 19% of the final distribution. The model gives 60%, the market 70%.",
 assessment="Bayern have had 4+ goals in 6 of 9 (3 of 3 at home), Leipzig in 5 of 8, and four of the last five meetings had six goals each."),
'Gençlerbirliği|away': dict(
 counter="Gençlerbirliği have a record of upsetting the Istanbul giants. They won 2-0 at Galatasaray in April 2026 and beat Fenerbahçe 2-1 this season, their most comparable fixture. New coach Bernd Storck has just arrived. Galatasaray are without Torreira (90% of minutes, suspended), lost 1-4 to Barcelona, and travel to Lille four days later.",
 assessment="Gençlerbirliği concede 2.14 goals and 2.19 xG per game and face 7.6 shots on target per game. Galatasaray are 5-1-1 in the league with xG 2.39 for / 1.03 against. The model (57%) is 14 points under the market (71%), so reliability is Low."),
'Manchester City|home__Ipswich Town': dict(
 counter="Foden is suspended, and City play AEK on Tuesday after losing 2-4 at home to PSG on Wednesday. City's home defence has leaked (1.6 goals conceded per home game), and Ipswich have scored in 75% of their matches (they won 3-2 at Crystal Palace).",
 assessment="City are 6-0-0 in the league. Ipswich have no clean sheets in 8 and lost to all three top sides they faced (0-2 v Liverpool, 2-5 at Man Utd, 2-4 v Arsenal). City won the last two meetings 4-1 and 6-0. Model 73%, market 78%."),
'Real Madrid|home__RB Leipzig': dict(
 counter="Leipzig average 2.88 goals per game, and Real lost 2 of their 7 comparable matches (1-2 at Atlético, 0-1 at Betis). Barcelona v Real follows four days later. The model (67%) is 8 points below the market (74%).",
 assessment="Real are 5-0-0 at home and 5-0-2 against comparable opposition, including a 2-1 win over Inter. Leipzig are 1-0-3 away."),
'Paris Saint-Germain|btts': dict(
 counter="Barcelona have kept 4 clean sheets in 10, and PSG's press could make this one-sided. The final distribution still gives about a one-in-four chance that one side blanks.",
 assessment="Barcelona have scored in all 10 matches, PSG in 9 of 10, and PSG kept only 1 clean sheet in 10. Barcelona are without Christensen, and Eric García is doubtful. Model 71%, market 75%."),
})

# alias the variants used for duplicate home teams
C['Manchester City|home__AEK Athens'] = C['Manchester City|home']
C['Real Madrid|home__Sevilla'] = C['Real Madrid|home']
C['Real Betis|o25__FC Barcelona'] = C['Real Betis|o25']
C['Manchester City|o25__AEK Athens'] = C['Manchester City|o25']
C['Manchester City|o25__Ipswich Town'] = dict(
 counter="City's league games are more controlled (over 2.5 in 67%, over 3.5 in 33%), and rotation between the PSG and AEK games could slow the tempo. 2-0 (10.8%) is the most likely score and 1-0 (8.3%) is fourth.",
 assessment="City have gone over in 4 of 5 home games, Ipswich in 6 of 8 (no clean sheets), and the last two meetings ended 4-1 and 6-0.")
C['Real Madrid|o25__RB Leipzig'] = C['Real Madrid|o25']


C['Royale Union Saint-Gilloise|home__Hapoel Be\'er Sheva'] = dict(
 counter="Union are without three regulars: Mac Allister (69% of minutes, cruciate ligament), Zorgane (52%) and Kricfalusi (49%). That cuts their attack by 7% and lifts Hapoel's by 6%. This home tie is played in Düsseldorf, not Brussels, which weakens home advantage. Union have drawn 4 of 6 home games (2-4-0), including 1-1 v Leuven and 1-1 v Real Sociedad in the last week. Sofascore also lists a league game for Union the next day, which, if correct, means heavy rotation.",
 assessment="Union are unbeaten in 13 (7-6-0, xG 2.14 for / 1.11 against) and beat comparable sides Antwerp 2-0, Plzeň 3-0 away and Anderlecht 3-0. Hapoel's xG is recorded for only 3 of 16 matches, and their only comparable result was a 1-2 loss at AZ (xG 1.07-2.71). The final figure leans on Superbet's price (72% de-vigged) more than on the model (66%), so reliability is Low.")
C['Ferencváros TC|home__Torreense'] = dict(
 counter="Ferencváros draw often at home (4-4-0; 3-4-1 in the league) and concede chances, with 1.93 xG against per home game where measured. Torreense, a second-tier Portuguese side, won 2-1 at Lillestrøm in MD1, and their xG is recorded for only 2 of 10 matches, so their strength is poorly measured.",
 assessment="Ferencváros have lost once in 19 and are 8-2-0 in European ties this season, including 3-1 at Celtic and 2-1 v Plzeň. Torreense have won 2 of 10, failed to score in 40%, and lost 1-2 at home to Sunderland on xG 0.04-1.79. The model (64%) and Superbet (69% de-vigged) broadly agree; reliability is Low because both teams' xG coverage is thin.")

# Clubs that are the home side in two uploaded fixtures: generic keys above refer to one specific opponent.
DEFAULT_AWAY = {'FC Bayern München': 'RB Leipzig', 'AS Roma': 'ŠK Slovan Bratislava', 'Fenerbahçe': 'Alanyaspor',
                'Real Betis': 'FC Barcelona', 'Manchester City': 'AEK Athens'}
for k in [k for k in C if '__' not in k]:
    home, mkt = k.split('|')
    v = C.pop(k)
    if v is None or mkt.startswith(('home#', 'o25#')):
        continue
    if home == 'Real Madrid':
        continue  # both Real Madrid entries already carry explicit opponent keys
    if home in DEFAULT_AWAY:
        C.setdefault(f'{home}|{mkt}__{DEFAULT_AWAY[home]}', v)
    else:
        C[f'{home}|{mkt}__*'] = v


def get(home, away, market):
    return C.get(f'{home}|{market}__{away}') or C.get(f'{home}|{market}__*')
