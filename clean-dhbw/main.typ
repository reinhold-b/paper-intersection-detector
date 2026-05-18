#import "@preview/clean-dhbw:0.3.1": *
#import "glossary.typ": glossary-entries
#import "@preview/fletcher:0.5.8": diagram, node, edge, shapes
#import "@preview/zebraw:0.6.1": zebraw
#import "@preview/lovelace:0.3.0": *
#import "@preview/pavemat:0.2.0": pavemat
#import "@preview/cetz:0.4.2": canvas, draw
#import "@preview/cetz-plot:0.1.3": *

// Zebraw-Konfiguration für Code-Blöcke im Dokument
#let code-block(
  caption: "",
  code-content,
  highlight-lines: (),
) = {
  figure(
    caption: [#caption],
    zebraw(
      numbering: true,
      numbering-separator: true,
      lang: true,
      radius: 8pt,
      highlight-lines: highlight-lines,
      highlight-color: rgb("#50dd96").lighten(70%),
      comment-color: rgb("#87ceeb").lighten(60%),
      comment-flag: "",
      code-content
    )
  )
}

#set math.mat(gap: 1em, delim: "[")

// Element colors
#let colors = (
  alkaline-metal: rgb("#8989ff"),
  alkaline-earth: rgb("#89a9ff"),
  metal: rgb("#89c9ff"),
  metalloid: rgb("#ffa959"),
  nonmetal: rgb("#59d9d9"),
  halogen: rgb("#ffff59"),
  noble-gas: rgb("#89ff89"),
  lanthanide: rgb("#ff8989"),
  synthetic: rgb("#525252"),
)


#show: clean-dhbw.with(
  title: "Entwicklung eines klassischen Kreuzungsdetektors",
  authors: (
    (name: "Reinhold Brant", student-id: "7261389", course: "STG-TINF23ITA", course-of-studies: "Informatik", company: (
      (name: "Robert Bosch GmbH", post-code: "76131", city: "Karlsruhe")
    )),
    // (name: "Juan Pérez", student-id: "1234567", course: "TIM21", course-of-studies: "Mobile Computer Science", company: (
    //   (name: "ABC S.L.", post-code: "08005", city: "Barcelona", country: "Spain")
    // )),
  ),
  type-of-thesis: "Studienarbeit",
  at-university: false, // if true the company name on the title page and the confidentiality statement are hidden
  bibliography: bibliography("sources.bib"),
  date: datetime.today(),
  glossary: glossary-entries, // displays the glossary terms defined in "glossary.typ"
  language: "de", // en, de
  supervisor: (company: "John Appleseed", university: "Prof. Dr. Daniel Düsentrieb"),
  university: "Duale Hochschule Baden-Württemberg",
  university-location: "Stuttgart",
  university-short: "DHBW",
  // for more options check the package documentation (https://typst.app/universe/package/clean-dhbw)
)

= Packages to use
- fletcher
- lovelace
- pavemat (für image darstellungen und ähnliches mit pixeln)
- showybox für theoreme und so
- lilaq (data visu)
- zebraw for code




= Abstract
Bei der CAuDri-Challenge - CAuDri steht für Cognitive Autonomous Driving - treffen sich verschiedene Hochschulgruppen aus ganz Deutschland, um ihre autonomen Modellfahrzeuge in zwei Disziplinen, dem Free Drive und dem Obstacle Evasion, gegeneinander antreten zu lassen. Dabei muss das Fahrzeug auch Kreuzungen durchfahren können. In der aktuellen Version des Fahrzeugs werden Schilder an der Kreuzung erkannt und nach einer bestimmten Strecke hinter diesen gestoppt, um kurz vor der Haltelinie zum Stehen zu kommen. Eine Verbesserung dieses Systems ist eine Haltelinienerkennung. Diese ermöglicht ein präzisen Haltevorgang an der Haltelinie. Zusätzlich erfordern es die aktuellen Disziplinen der CAuDri-Challenge nur, an der Kreuzung den Spuren der Vorfahrtsstraße zu folgen. In einer neuen Disziplin der CAuDri-Challenge sollen aber beliebige Abbiegevorgänge an der Kreuzung möglich sein.

Ziel der Arbeit ist, eine Haltelinien- und Kreuzungserkennung zu entwickeln, die Abbiegespuren zuverlässig in vielen Situation erkennt. Außerdem soll es die Haltelinienerkennung ermöglichen, exakt an der Haltelinie zum Stehen zu kommen. Das gesamte Modul soll eine regelkonforme Durchfahrt in alle Kreuzungsrichtungen zuverlässig ermöglichen. Das Modul muss unabhängig vom Untergrund beziehungsweise anderen Störquellen robust und zuverlässig Haltelinien und Spuren erkennen.
= Einleitung
== Problemstellung
In der Caudri Challenge durchfährt das Fahrzeug autonom eine Strecke. Dabei nutzt es eine Kamera, um zu navigieren. In der Disziplin Free Drive muss das Fahrzeug so lange wie möglich ohne Steuerung von außen auch Kreuzungen korrekt erkennen und durchfahren. Um dies zu erreichen, muss die Kreuzungserkennung alle Haltelinien innerhalb der Kreuzung korrekt erkennen und anhand dieser die Kreuzung klassifizieren, bevor das Fahrzeug diese durchfahren kann.

Das Modul gibt die gewonnen Informationen über die Kreuzung nach der Berechnung an das Pfadplanungsmodul weiter, welches anschließend den korrekten Fahrtweg durch die Kreuzung berechnet.

Das Modul wird als klassische Kreuzungserkennung implementiert und nutzt dabei keine Deep Learning Verfahren. Das hat einige Vorteile für das Deployment des Moduls auf dem Fahrzeug. Zum Einen sind Ergebnisse des Moduls einfach zu interpretieren, da die Berechnungen des Moduls vollständig regelbasiert getroffen und nicht durch ein Modell berechnet werden. Außerdem können Parameter wie etwa für Winkelfilter, Längenfilter und andere regelbasierte Systeme besser angepasst werden, um Ergebnisse zu optimieren. Dazu wäre für einen Deep Learning Ansatz ein aufbereiteter Datensatz mit sauberen Labels notwendig, was durch den klassischen Ansatz wegfällt.
== Kreuzungen
Um eine zuverlässige Kreuzungserkennung auf dem Fahrzeug zu implementieren werden zuerst die Kreuzungen betrachtet, die das System erkennen soll. Innerhalb der Caudri-Challenge gibt es eine Menge an Kreuzungen, die sich durch die Position der Haltelinien, der Art der Haltelinien und der Straßenführung innerhalb der Kreuzung unterscheiden. Diese sind dokumentiert.
#grid(
  columns: (1fr, 1fr, 1fr), // Zwei Spalten mit gleicher Breite
  gutter: 5pt,        // Abstand zwischen den Bildern
  image("./assets/crossings/crossing1.png"),
  image("./assets/crossings/crossing2.png"),
  image("./assets/crossings/crossing3.png"),
  image("./assets/crossings/crossing4.png"),
  image("./assets/crossings/crossing5.png"),
  image("./assets/crossings/crossing6.png"),
)
Die zu erkennenden Kreuzungen sind folgendende:
- Ego- und Gegenspur Haltelinien durchgezogen
- Ego- und Gegenspur Haltelinie gestrichelt
- Gestrichelte Haltelinien an allen Spuren der Kreuzung
- Abknickende Vorfahrtsstraße links mit durchgezogenen Linien in der Ego- und Gegenspur
- Abknickende Vorfahrtsstraße links mit gestrichelten Haltelinien in der Ego- und Gegenspur
- Abknickende Vorfahrtsstraße links mit durchgezogener Haltelinie in der Gegenspur und der rechten Spur

Die zu erkennenden Kreuzungen sind standardisiert und sehen innerhalb der Strecke stets gleich aus.

= Technischer Kontext

= Modulübersicht

= Architektur und Datenfluss

= Entwicklungs- und Evaluationsprozess
Um aus einem Rohbild aus der `camera_preprocessing` Node Informationen zu gewinnen, wird das Rohbild innerhalb einer Pipeline verarbeitet. Innerhalb der Pipeline sind mehrere Designentscheidungen zu treffen, um ein bestmögliches Ergebnis zu erzielen.
Der Entwicklungsprozess wird in Iterationen durchgeführt, nach der jeder das Ergebnis der Pipeline evaluiert und getestet wird. 
== Bildvorverarbeitung
Das Rohbild der `camera_preprocessing` Node entspringt einer Kamera, die auf einem Gestell hinten am Fahrzeug angebracht ist. Dieses liefert ein schwarz-weiß Bild, welches dieses Modul nutzt, um Kreuzungen zu klassifizieren.

Es stellt sich während der Entwicklung heraus, dass es von Vorteil ist, das Bild in einigen Schritten zu verarbeiten, bevor es von der Systempipeline verarbeitet wird.

=== Bildperspektive
Bevor die allgemeine Vorverarbeitungspipeline erklärt wird, muss entschieden werden, ob für das Modul eine Frontalansicht der Kamera oder die Vogelperspektive gewählt wird, die eine perspektivische Verzerrung der Frontalansicht ist. TODO: Bilder einfügen
Allgemein haben sowohl die Frontalansicht, als auch die Vogelperspektive (auch `BEV` für `Birds Eye View`) Vorteile und Nachteile, die im Folgenden aufgeführt werden. Diese gehen auch Tests während der Entwicklung hervor.

#table(
  columns: 3,
  [*Kriterium*], [*Frontalansicht*], [*Vogelperspektive (BEV)*],
  [Linienerkennung], [Gut - Linien sind deutlich sichtbar, vertikale Linien sind aber stets geneigt], [Sehr gut - Linien sind orthogonal],
  [Perspektivische Verzerrung], [Ja - Objekte verzerrt], [Nein - Orthogonale Abbildung],
  [Schärfe], [Gesamtheitlich scharfes Bild], [Oberer Bereich verzerrt],
  [Rechenaufwand], [Niedrig], [Höher (Transformation notwendig)],
  [Abstand zu Objekten], [Erschwert], [Direkt messbar],
  [Sichtfeld], [Sehr groß, vor allem aber in Weitsicht], [Geringer, aber auf Nahbereich fokussiert]
)

Während der Entwicklung müssen nun diese Kriterien betrachtet und abgewogen werden. Für den vorliegenden Anwendungsfall sind vor allem folgende Kriterien relevant:
+ Perspektivische Verzerrung
+ Schärfe
+ Sichtfeld

Während der Entwicklung hat es sich als Schwierigkeit herausgestellt, dass die Frontalansicht einen weiten Blick über die Straße hat. Zwar könnte es von Vorteil sein, um die Kreuzung früher zu erkennen, aber tatsächlich ist der Großteil der Weite, die die Frontalansicht liefert, für die Kreuzungserkennung von keiner Relevanz. Negativ ins Gewicht fällt dabei auch, dass der Kreuzungsbereich im vorderen Bildbereich stark gestaucht ist und dadurch alle Haltelinien sowie der gesamte Kreuzungsbereich in einem kleinen Bereich der ROI zusammenkommen.

Außerdem ist die perspektivische Verzerrung der Frontalansicht ein Nachteil bei der Erkennung von Haltelinien, da Linien nicht mehr orthogonal im Bild erscheinen, sondern in Richtung eines Fluchtpunktes. Das ist vor allem für Winkelberechnungen unvorteilhaft.

Ein Nachteil der Vogelperspektive ist die Unschärfe im oberen Teil des Bildes, die durch die Transformation zustandekommt. Dadurch kann es schwer sein, Linien zu erkennen, da diese stark verzerrt sind. Das ist aber durch eine Vorverarbeitungspipeline zu beheben, weswegen für das Modul die Vogelperspektive als Bildperspektive gewählt wird.

TODO: Trafo in BEV erklären?

=== Bildentzerrung
Durch die Transformation in die Vogelperspektive sind in den oberen Bereichen des Rohbildes starke Verzerrungen, sodass die Linienerkennung die gegenüberliegende Haltelinie nicht erkennen kann.


==== Gaussian Blur

Ein Ansatz, um Verzerrungen im Bild zu bereinigen, ist es, den gesamten Bildbereich mit einem Filter zu verarbeiten. Dafür kommt beispielsweise die `Gaussche Unschärfe` in Betracht, die auf Basis einer Faltung dem gesamten Bild eine Unschärfe zufügt.

Der Kernel für diese Faltung wird aufgrund folgender Vorschrift durchgeführt.

#figure(
caption: "Gaussian Blur Kernelvorschrift",
$G(x,y) = frac(1, 2pi * sigma)e^(frac(x^2+y^2, 2sigma^2))$ 
) <gauss-1>

Aus dieser Vorschrift entsteht ein Kernel, der Pixel näher zur Mitte des Kernel stärker gewichtet als Pixel, die am Rand des Kernels liegen. Ein Beispielkernel `5x5` könnte wie folgt aussehen (siehe @gaussian-kernel-5x5).

#figure(
caption: "Beispiel Gaussian Kernel 5x5",
$
  mat(
    0.0037, 0.0147, 0.0221, 0.0147, 0.0037;
    0.0147, 0.0586, 0.0881, 0.0586, 0.0147;
    0.0221, 0.0881, 0.1325, 0.0881, 0.0221;
    0.0147, 0.0586, 0.0881, 0.0586, 0.0147;
    0.0037, 0.0147, 0.0221, 0.0147, 0.0037;
  )
$
) <gaussian-kernel-5x5>
Das Bild wird nun mit diesem Kernel gefaltet. Hierbei ist der Wert jedes neuen Pixels im gefilterten Bild eine gewichtete Summe aus den Nachbarpixeln (in @gaussian-kernel-5x5 beispielsweise `5x5` Umgebung) @gauss-source (S. 393).

Innerhalb des Moduls kann die in `OpenCV` vorhande Funktion `cv2.GaussianBlur(img, (5, 5))` verwendet werden.

TODO HIER BILD EINFÜGEN AUS DER PIPELINE

Der Gauss-Filter ist nützlich, um Rauschen aus dem Bild zu entfernen und damit auch verzerrte Stellen des Bildes weicher zu machen, sodass die Linienerkennung trotz Verzerrung durch die BEV gute Ergebnisse liefert. Ein Problem des Gauss-Filters ist aber, dass er sowohl Verzerrungen, als auch bereits klare Kanten weicher macht. Das führt zu schlechteren Ergebnissen bei bereits klaren Kanten.

==== Bilateraler Filter
Um den Schwächen des Gauss-Filters entgegenzuwirken, wird der bilaterale Filter in Betracht gezogen. Der Vorteil des bilateralen Filters ist es, dass er Verzerrungen aufweicht, während scharfe Kanten erhalten bleiben @bil-fil (S. 779). 

Der bilaterale Filter nutzt dabei zwei Gaussche-Kernel, um den Wert des gefilterten Pixels zu berechnen. Ein Filter ist dabei ein räumlicher Filter, welcher ähnlich der `Gausschen Unschärfe` arbeitet. Er gewichtet nah gelegene Pixel stärker als weiter entfernte. Der Unterschied zum einfachen Gausschen-Filter ist aber, dass zusätzlich ein Intensitätskernel genutzt wird, welcher Pixel stark gewichtet, die ähnliche Intensität aufweisen und Pixel mit stark Gradienten in Intensität schwach gewichtet @bil-fil (S. 779f).

Der bilaterale Filter weist im Vergleich zum Gauss-Filter aber höhere Rechenkosten auf, die aber mit Blick auf das Ergebnis akzeptabel sind @bil-fil (S. 779). Deswegen wird dieser Filter in der Pipeline genutzt.

==== Median Blur

Der Median-Blur arbeitet ähnlich zu den andern Filtern. Dabei wird aber kein Gauss-Kernel erzeugt, sondern alle Pixelwerte innerhalb der Kernelfläche in aufsteigender Reihenfolge sortiert und das mittlere Element (der Median) als neuer Wert des betrachteten Pixels gesetzt. Dies macht den Filter besonders effektiv bei der Reduktion von Salz- und Pfeffer-Rauschen (engl. `Salt-and-Pepper` Noise), da extreme Ausreißer durch den Median-Wert ersetzt werden.

Auch der Median-Blur hat einen hohen Rechenaufwand, wird aber in Kombination mit dem bilateralen Filter genutzt, um zusätzlich `Salt-and-Pepper` Rauschen aus dem Bild zu entfernen. Auch dieses kann durch die Transformation in BEV erzeugt werden.

TODO QUELLE UND BILDER, CODE EINFÜGEN

=== Morphologisches Öffnen und Schließen


=== Minimierung von Lichtverschmutzung




== Kantenerkennung
Ziel des ersten Entwicklungsinkrements ist das Extrahieren von Linien aus dem Rohbild. Dafür werden verschiedene Methodiken betrachtet, mit denen aus dem Rohbild eine Menge an Linien extrahiert werden kann, die dann in weiteren Schritten zum Bestimmen der Ego- und Opp-Haltelinien genutzt werden können.

=== Canny Edge Detector
Bevor Linien aus dem Rohbild extrahiert werden können, muss dieses erstmal vorverarbeitet werden. Der erste Verarbeitungsschritt ist es, aus dem Rohbild Kanten zu detektieren. Kantendetektion ist ein Verfahren, bei dem versucht wird, die Kanten von Flächen innerhalb eines Bildes zu detektieren, indem Stellen innerhalb des Bildes ermittelt werden, an denen die Intensitätsänderung der Pixelhelligkeiten besonders stark ist @xu2017canny [S.53]. 

Der `Canny Edge Detection` Algorithmus besteht aus mehreren Schritten. Das Rohbild ist dabei ein Graustufenbild und nicht farbig.

1. Im ersten Schritt wird das Bild entrauscht. Dafür wird der `Gaussian Blur (dt. Gaußscher Weichzeichner)` auf das gesamte Bild angewandt. Dieser wird nach folgener Vorschrift durchgeführt $G(x,y) = frac(1, 2pi * sigma)e^(frac(x^2+y^2, 2sigma^2))$ <gauss>. 
2. Nun das Bild mit zwei Matrizen `Gx` und `Gy`, den so genannten `Sobel-Filtern` gefaltet. Diese sind wie folgt definiert.
#grid(
  columns: 2,
  $ G_x = mat(
  -1, 0, 1;
  -2, 0, 2;
  -1, 0, 1;
  ) $,
$ G_y = mat(
   1,  2,  1;
   0,  0,  0;
  -1, -2, -1
) $,
) 
Die Faltung mit diesen zwei Matrizen resultiert in einem neuen Bild, welches an den Stellen, an denen der Gradient der Pixelwerte zwischen benachbarten Pixeln am größten ist, hellere Pixel hat als an Stellen, wo der Gradient nicht so stark ist. Benachbarte Pixel, die alle den selben Wert haben, werden nach der Faltung einen Pixelwert von 0 haben, weswegen sie schwarz sind. Da sowohl entlang der x-Achse als auch der y-Achse gefaltet wird, wird jedem Pixel somit ein Vektor der Größe 2x1, welcher die Intensität der Änderung in der respektiven Richtung anzeigt. <cannyangle>

3. Die Werte aus dem Spaltenvektor mit den Intensitätswerten des Gradienten werden nun benutzt, um die Richtung der Kante zu bestimmen. Die Richtung der Änderung wird mit $theta = arctan(frac(G_y, G_x))$ berechnet. Es kann vorkommen, dass $G_x$ den Wert Null besitzt. In diesem Fall wird der Winkel als 90 Grad angesetzt.
4. Nun wird auf die gesamte Intensitätsmatrix nach der Schritt 3 die `Non-Maximum Suppression` durchgeführt. Diese betrachet nun in Richtung der maximalen Änderung (Schritt 3) die Intensitätswerte aus der Gradientenmatrix aus Schritt 2. Dabei wird entlang dieser Richtung das lokale Maximum erhalten und die restlichen Pixelwerte auf 0 gesetzt. Somit wird hier eine klare Kante errechnet (siehe @nms).
$ "NMS"(x, y) = cases(
  M(x, y) & "falls" M(x, y) >= M(g_1) "und" M(x, y) >= M(g_2),
  0 & "sonst"
) $ <nms>
5. Nun werden zwei Schwellenwerte $t_"high"$ und $t_"low"$ festgelegt. Anhand dieser Schwellenwerte werden Pixel in drei Kategorien unterteilt:
      - Keine Kante
      - Schwache Kante
      - Starke Kante
  Canny klassifiziert schwache Kanten nur als Kante, wenn sie mit einem Pixel verbunden sind, der als starke Kante klassifiziert wurde oder über eine Kette schwacher Pixel eine Verbindung vorliegt. Pixel mit Wert unterhalb des Schwellenwerts werden ausgefilter. So entsteht ein Bild, welches mit hellen Pixeln die Kanten des Rohbildes darstellt @canny [S.127ff].

== Linienextraktion
Das gewonnene Bild wird nun zur Linienextraktion verwendet. 

Allgemein werden zwei Verfahren für die Detektion von Liniensegmenten geprüft, welche oft in der digitalen Bildverarbeitung Verwendung finden. Diese sind zum einen die `Hough Transformation` und der `Line Segment Detector (LSD)` Algorithmus nach Rafael Grompone von Gioi et altera. 

=== Line Segment Detector
Der LSD Algorithmus ist ein geometrischer Extraktionsalgorithmus, welcher in linearer Zeit subpixel genaue Ergebnisse zu Liniensegmenten liefern kann. Auch der LSD basiert auf der Detektion von sich lokal stark ändernden Pixelwerten. Der LSD erstellt ein Vektorfeld, dessen Vektoren orthogonal zu den Richtungsvektoren der Gradientenänderung stehen (siehe cannyangle todo). Dies sieht dann wie folgt aus.
#figure(
  image("assets/lsd_vecfield.png"),
  caption: "LSD Vektorfeld"
) <lsd-vec> @lsd
Aus diesen Vektoren werden so genannte `line support regions` generiert die in @lsd-vec. Diese Regionen sind potentielle Linien. Um diese `line support regions` Wird ein Rechteck gelegt, dessen Ausrichtung entlang der Ausrichtung der Vektoren in diesem Feld liegt.

Nun wird jedes Rechteck durch das `Helmholtz-Prinzip` und der `a contrario-Methode` validiert. Nach dieser Methode wird ein Modell erstellt, welches in seiner Gesamtheit aus Rauschen besteht. Es wird nun angenommen, dass das Rechteck in solch einer Struktur nicht wiedergefunden werden kann. Das Rechteck wird validiert, wenn auf diesem Rausch-Modell nur eine sehr geringe Anzahl bis garkeine Ereignisse des selben Rechtecks auftreten @lsd (S. 36f).

Ein großer Vorteil des LSD ist, dass er vollständig ohne das Anpassen von Parametern
funktioniert und Parameter innerhalb des Algorithmus garnicht geändert werden können.

todo maybe mehr später falls gebraucht

O(n)

=== Hough Transformation

Auch die Hough-Transformation ist ein Algorithmus, welcher zur Detektion von Linien genutzt
wird. 

Innerhalb eines Bildes können alle geraden Linien als eine zwei-Parameter Familie
gesehen werden. Folglich wird jede Linie mit zwei Parametern $theta$ und $rho$ beschrieben.
Es wäre naheliegend, eine Linie in der Form $y = m*x+b$ darzustellen. Diese Darstellung
scheitert aber daran, dass vertikale Linien mit einer unendlichen Steigung beschrieben
werden würden, was digitale Berechnungen kompliziert macht. 

==== Hough Raum
Die einfache Darstellung einer Linie im Folgenden trotzdem genutzt, um den `Hough Raum` zu erklären. Man stelle sich eine Menge $M_P$ an Punkten vor, die innerhalb eines Bilds auf einer Linie liegen. Diese Linie kann mit der oben beschriebenen Formel für eine Linie innerhalb des Bilds beschrieben werden. Dabei sind $x_i$ und $y_i$ beliebige Punkte auf der Linie, die aber vorerst unbekannt sind. Nun wird die Beschreibung der Linie zu $b = -m*x+y$ umgestellt. Nimmt man nun einen Punkt aus $M_P$ und setzt ihn in die genannte Formel ein, erhält man eine Linie im Parameterraum (siehe @img-param-space).

Diese Linie beschreibt nun alle Linien im Bildbereich, die diesen Punkt kreuzen. Dies wird nun für alle Punkte der Menge durchgeführt. Es ergibt siche ein Punkt $(m, b)$, welcher die gesuchte Linie im Bildraum darstellt, auf der alle Punkte der Menge $M_P$ liegen. Nimmt man nun einen Punkt, der nicht auf der gesuchten Linie liegt, erhält man eine Linie im Parameterraum, die keinen gemeinsamen Schnittpunkt mit den anderen gefundenen Linien besitzt.
#figure(
  caption: "Bild- und Parameterraum https://www.youtube.com/watch?v=XRBc_xkZREg",
  image("assets/img-param-space.png")
) <img-param-space>
==== Linienbestimmung
Um nun innerhalb eines Bildes Linien zu erkennen, wird der jüngst beschriebene Hough-Raum verwendet. Dafür wird der Parameterraum $P$ quantisiert. Dafür wird eine Matrix $A(m, b)$ über dem Parameterraum erstellt, die auch `Akkumulator-Array` genannt wird. Zu Beginn des Algorithmus wird dieses Array mit Nullen besetzt und sieht folglich so aus:

#align(center)[#canvas({
  let rows = 5
  let cols = 5
  let cell-size = 0.6
  
  // 1. Zeichne das Gitter (Akkumulatorzellen)
  for i in range(cols + 1) {
    draw.line((i * cell-size, 0), (i * cell-size, rows * cell-size), stroke: gray + 0.5pt)
  }
  for j in range(rows + 1) {
    draw.line((0, j * cell-size), (cols * cell-size, j * cell-size), stroke: gray + 0.5pt)
  }

  // 2. Akkumulator mit Nullen gefüllt
  // Schreibe "0" in jede Zelle
  for i in range(cols) {
    for j in range(rows) {
      let x = i * cell-size + cell-size / 2
      let y = j * cell-size + cell-size / 2
      draw.content((x, y), [0], size: 10pt)
    }
  }

  // 3. Achsenbeschriftung
  draw.line((-0.2, 0), (cols * cell-size + 0.5, 0), mark: (end: ">"))
  draw.content((cols * cell-size + 0.7, 0), [$m$])
  
  draw.line((0, -0.2), (0, rows * cell-size + 0.5), mark: (end: ">"))
  draw.content((0, rows * cell-size + 0.7), [$b$])
})]
Nun hat ein Kantenerkennungsalgorithmus Punkte innerhalb des Bildes erkannt hat, die potenzielle Linien sein könnten. Diese sind eine Menge $K$. Aus Effizienzgründen werden nicht die klassischen Geradenparameter $m$ und $b$ verwendet, sondern die Normalform mit den Parametern $rho$ (Abstand) und $theta$ (Winkel).

Die Normalform einer Linie wird durch folgende Formel definiert:

#figure(
  caption: "Normalform einer Geraden im Hough-Raum",
  $rho = x*cos(theta)+y*sin(theta)$
) <hough-line>

Dabei ist:
- $rho$ der senkrechte Abstand von der Linie zum Ursprung (Betrag zwischen 0 und der Bilddiagonale)
- $theta$ der Winkel des Normalenvektors der Linie zur x-Achse (typischerweise 0° bis 180°)

Der Vorteil dieser Parametrisierung ist, dass sie die gesamte Bildebene abdeckt und Singularitäten bei vertikalen Linien vermeidet, die bei der Steigungsform $m = ∞$ auftreten würde.

*Ablauf des Hough-Transform-Algorithmus:*

Für jeden erkannten Kantenpunkt $(x_i, y_i)$ aus $K$ werden alle möglichen Linien berechnet, die durch diesen Punkt verlaufen. Dies geschieht durch die Diskretisierung des $theta$-Bereichs in Schritte $theta_j$ und das Berechnen der entsprechenden $rho$-Werte nach obiger Formel. Im Akkumulator-Array (siehe oberes Diagramm) wird für jede berechnete Parameterkombination $(rho, theta)$ ein Zähler erhöht - ein Punkt "stimmt" für die Parameter.

Nach der Verarbeitung aller Kantenpunkte enthält der Akkumulator Maxima an den Parameterkombinationen, die vielen Kantenpunkten entsprechen. Das untere Diagramm zeigt ein Beispiel mit 3 kollinearen Kantenpunkten: diese erzeugen Votes in vertikaler, horizontaler und diagonaler Richtung, die sich in der Mitte treffen und ein Maximum mit 3 Stimmen bilden. Diese Maxima repräsentieren die tatsächlich im Bild vorhandenen Linien.

Das gefüllte Akkumulator-Array nach der Verarbeitung könnte beispielsweise wie folgt aussehen:

#align(center)[#canvas({
  let rows = 5
  let cols = 5
  let cell-size = 0.6
  
  // 1. Zeichne das Gitter (Akkumulatorzellen)
  for i in range(cols + 1) {
    draw.line((i * cell-size, 0), (i * cell-size, rows * cell-size), stroke: gray + 0.5pt)
  }
  for j in range(rows + 1) {
    draw.line((0, j * cell-size), (cols * cell-size, j * cell-size), stroke: gray + 0.5pt)
  }

  // 2. Akkumulator mit simulierten Votes gefüllt
  // Mitte des Grids
  let center-x = 2
  let center-y = 2
  
  // Alle Zellen mit 0 initialisieren
  let matrix = ()
  for j in range(rows) {
    let row = ()
    for i in range(cols) {
      row.push(0)
    }
    matrix.push(row)
  }
  
  // Votes für senkrechte Linie (vertikal)
  for j in range(rows) {
    matrix.at(j).at(center-x) += 1
  }
  
  // Votes für waagerechte Linie (horizontal)
  for i in range(cols) {
    matrix.at(center-y).at(i) += 1
  }
  
  // Votes für diagonale Linie
  for k in range(rows) {
    matrix.at(k).at(k) += 1
  }
  
  // Maximum finden
  let max-val = 0
  let max-x = 0
  let max-y = 0
  for j in range(rows) {
    for i in range(cols) {
      if matrix.at(j).at(i) > max-val {
        max-val = matrix.at(j).at(i)
        max-x = i
        max-y = j
      }
    }
  }
  
  // Zelle mit Maximum rot markieren
  draw.rect(
    (max-x * cell-size, max-y * cell-size),
    ((max-x + 1) * cell-size, (max-y + 1) * cell-size),
    fill: rgb("#ff0000").lighten(40%),
    stroke: none
  )
  
  // Werte in Zellen schreiben
  for i in range(cols) {
    for j in range(rows) {
      let x = i * cell-size + cell-size / 2
      let y = j * cell-size + cell-size / 2
      let val = matrix.at(j).at(i)
      draw.content((x, y), [#val], size: 10pt)
    }
  }

  // 3. Achsenbeschriftung
  draw.line((-0.2, 0), (cols * cell-size + 0.5, 0), mark: (end: ">"))
  draw.content((cols * cell-size + 0.7, 0), [$m$])
  
  draw.line((0, -0.2), (0, rows * cell-size + 0.5), mark: (end: ">"))
  draw.content((0, rows * cell-size + 0.7), [$b$])
})]

Die rot markierte Zelle mit dem Wert 3 zeigt das Maximum im Akkumulator-Array, das von drei kollinearen Kantenpunkten erzeugt wird. Diese drei Votes entstehen durch die vertikale, horizontale und diagonale Ausrichtung der Kantenpunkte. Das detektierte Maximum $(rho_0, theta_0)$ wird als Parameterpaar für eine erkannte Linie verwendet. Nach der Verarbeitung aller Kantenpunkte können weitere Maxima ermittelt und damit mehrere Linien im Bild lokalisiert werden @hough.

=== Pipeline für die Linienerkennung
Es wurden nun zwei Algorithmen zur Erkennung von Linien in einem Bild vorgestellt.

Durch praktische Tests hat sich der LSD Algorithmus dabei als die optimale Lösung für die Kreuzungserkennung erweisen, da dieser Algorithmus ohne weiteres Tuning von Parametern sehr zufriedenstellend funktioniert. Außerdem ist zu nennen, dass der LSD mit einer Zeitkomplexität von O(n) deutlich effizienter funktioniert, als die Hough Transformation @meng2024review (S.27). Somit wird für die Liniendetektion der Kreuzungserkennung der Canny Algorithmus mit nachgeschaltetem LSD Algorithmus gewählt.

#let diagram-content = align(center)[#diagram(
  spacing: 10pt,
  cell-size: (10mm, 10mm),
  edge-stroke: 1pt,
  edge-corner-radius: 5pt,
  mark-scale: 70%,
  
  node((0, 0), [Bild], width: 25mm, fill: rgb("#89c9ff").lighten(60%), stroke: 1pt + rgb("#89c9ff").darken(20%), shape: shapes.hexagon.with()),
  edge((0, 0), (1, 0), "->"),
  
  node((1, 0), [Canny], width: 25mm, fill: rgb("#ffff59").lighten(60%), stroke: 1pt + rgb("#ffff59").darken(20%), corner-radius: 5pt),
  edge((1, 0), (2, 0), "->"),
  
  node((2, 0), [LSD], width: 25mm, fill: rgb("#ffff59").lighten(60%), stroke: 1pt + rgb("#ffff59").darken(20%), corner-radius: 5pt),
  edge((2, 0), (3, 0), "->"),
  
  node((3, 0), [Linien], width: 25mm, fill: rgb("#ff89f7").lighten(60%), stroke: 1pt + rgb("#ff89f7").darken(20%), shape: shapes.hexagon.with()),
)]

#figure(
  caption: [Pipeline für Linienerkennung],
  diagram-content
) <pipeline-1>

== Linienvorverarbeitung

=== Linienlängenfilter 
Nachdem das Modul nun Linien aus einem Rohbild erkennen kann, sind noch einige Schritte nötig, um das Ergebnis der Linienerkennung besser nutzbar zu machen. Zum Einen ist es wichtig, zu kurze Linien aus der Menge der gefundenen Linien herauszufiltern. Das ist wichtig, da Haltelinien nach der Erkennung immer eine bestimmte Länge haben. 

Eine Linie $L$ sei innerhalb des Moduls als ein Vektor aus vier Werten dargestellt. Dieser Vektor $L$ sei beschrieben durch $L = vec("x_1, y_1, x_2, y_2")$. Die Koordinaten innerhalb des Vektors stellen die Anfangs- und Endpunkte der Linie dar. Somit kann die Länge der Linie durch die euklidische Distanzformel $"length"=sqrt((x_2 - x_1)^2 + (y_2 - y_1)^2)$ berechnet werden. Es ergibt sich folgender Code.

#code-block(
  caption: [Längenfiltration erkannter Linien],
  ```python
def filter_by_length(self, lines, min_l: float = 70.0, max_l=10000):
    res = []
    for line in lines:
        x1, y1, x2, y2 = line[0]
        length = math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)
        if length >= min_l and length <= max_l:
            res.append(line)
    return res
  ```,
  highlight-lines: (
    (6, [Euklidische Distanzformel zur Berechnung der Linienlänge]),
  )
) <filter-length>

Es werden nur Linien mit einer Länge zwischen `min_l` und `max_l` behalten. Dies ist wichtig, um Rauschlinien auszuschließen und nur relevante Strukturen zu verarbeiten.

TODO: anfügen irgendwo, dass Variablennamen gekürzt werden aus Lesbarkeitsgründen

Durch Tests auf Sicht hat sich für einen ersten Längenfilter der Linien eine Pixellänge von `20` bewährt. Damit werden vorerst kleine Rauschlinien aus der potentiellen Menge entfernt.

Filterung der Linien ist wichtig, da eine geringe Menge an Linien dazu führt, dass das später zu implementierende System weniger Möglichkeiten hat, eine falsche Linie auszuwählen.

TODO: Bilder aus dem Modul aufnehmen und hier rein pasten

=== Region of Interest Filter

Der Region-of-Interest-Filter (ROI-Filter) beschränkt die verarbeiteten Linien auf einen definierten Bereich des Bildes. Dies ist besonders hilfreich, um irrelevante Bildbereiche auszuschließen und die Verarbeitung auf die Bereiche zu konzentrieren, in denen tatsächlich relevante Kreuzungen zu erwarten sind. Der ROI wird durch relative prozentuale Grenzen definiert, die automatisch auf die tatsächliche Bildgröße skaliert werden.

Das Konzept des ROI-Filters lässt sich algorithmisch wie folgt darstellen:

#block(
  width: 100%,
  inset: 1em,
  fill: rgb("#f5f5f5"),
  [
    *Algorithmus 1: ROI-basierte Linienfilterung*
    
    *Eingabe:* Liste von Linien, Bildhöhe und -breite, ROI-Grenzen (in %)
    
    *Ausgabe:* Gefilterte Liste von Linien
    
    + Konvertiere relative ROI-Grenzen in absolute Pixelkoordinaten
    + Für jede Linie: Behalte sie nur, wenn beide Endpunkte in der ROI liegen
    + Gib die gefilterten Linien zurück
  ]
) <roi-algo>

Für die relativen ROI-Grenzen wird durch Tests eine Definition von `FILTERING_ROI_REL_RLTB = (0.80, 0, 0, 0.815)` gewählt.

TODO: auch hier evtl bild der roi

=== Linienfusion

Nachdem Linien nach Ort und Länge gefiltert wurden, ist beim Testen ein Problem zu beobachten. Durch Sichttests wird festgestellt, dass in vielen Fällen tatsächliche Haltelinien durch mehrere, unterbrochene Linien dargestellt werden, die logisch zu einer Linie im Bild gehören. Außerdem sind die zu erkennenden Linien stets gerade, es werden also keine Kurven erkannt. Deswegen ist es ein sinnvoller Schritt, die gefunden Linien zu fusionieren. Die Idee ist, Linien, die örtlich nebeneinander liegen und ähnliche Winkel haben, zu einer Linie zu fusionieren. Ziel ist es also, aus einer Menge an Linien eine einzelne repräsentative Linie zu finden.

Die Fusion der Linien läuft wie folgt ab:

#block(
  width: 100%,
  inset: 1em,
  fill: rgb("#f5f5f5"),
  [
    *Algorithmus 2: Linienfusion durch Greedy Clustering*
    
    *Eingabe:* Liste von Linien, Winkeltoleranz, Distanztoleranz
    
    *Ausgabe:* Liste der fusionierten Linien
    
    + Berechne Winkel und Mittelpunkt jeder Linie
    + Gruppiere Linien mit ähnlichem Winkel und nah beieinander liegendem Mittelpunkt (Greedy Clustering)
    + Für jede Gruppe: Sammle alle Endpunkte, nutze PCA zur Hauptachsen-Berechnung
    + Projiziere Endpunkte auf die Hauptachse und finde die Extrempunkte
    + Diese Extrempunkte werden die Endpunkte der fusionierten Linie
    + Gib die Liste der fusionierten Linien zurück
  ]
) <fuse-algo>

Im Folgenden werden die Schritte des Algorithmus näher erläutert.

==== Winkel- und Mittelpunktsberechnung
Um die Winkel und Mittelpunkte der Linien zu berechen, wird eine Linie zuerst als Vektor dargestellt. Durch Differenzbildung zwischen den Start- und Endpunkten erhalten wir einen Linienvektor. Dieser sieht wie folgt aus: $l = vec(x_2 - x_1, y_2 - y_1)$. Nun wird aus diesem Vektor mit `math.atan2(dy, dx)` der Winkel der Linie bestimmt. Der Mittelpunkt wird durch Division des Vektors mit Zwei bestimmt.
==== Gruppierung der Linien
Nun wird über alle Linien iteriert. Bei jeder Iteration `i` wird nun geprüft, ob diese Linie bereits überprüft wurde. Ist dies nicht der Fall, wird in einer weiteren Schleife im Bereich $[i + 1, n]$ der Differenzwinkel und die Differenzdistanz des Elements $j$ zum Element $i$ berechnet. Liegen diese Werte innerhalb eines vorgegebenen Toleranzbereichs, werden sie in eine Gruppe mit dem Element $i$ hinzugefügt. Es bilden sich somit Gruppen aus Linien mit ähnlicher Ausrichtung, die nah beieinander liegen.
Gruppen mit zu wenigen Mitgliedern werden gelöscht.
==== Principal Component Analysis
Für jede Linie werden die Start- und Endpunkte bestimmt. Die zuvor bestimmten Gruppen werden somit also zu 2D-Punktemengen. Nun wird die `Principal Component Analysis` (PCA) verwendet, um die Gerade zu finden, die am besten durch die gesamte Punktwolke passt.

Um die PCA durchzuführen, müssen die Punkte vorverarbeitet werden. Zum Einen wird der Mittelpunkt aller Punkte bestimmt und anschließend jeder Punkt um diesen Mittelwert verschoben. Das hat zur Folge, dass der Mittelwert aller Punkte nun im Ursprung liegt @pca (S. 433). Nun wird die `Single Value Decomposition` (SVD) genutzt, um die Punktwolke in Hauptachsen zu zerlegen. Im Code wird dies mit folgendem Befehl durchgeführt: `U, S, Vt = np.linalg.svd(pts - mean)`. `Vt` liefert nun eine Matrix mit den Hauptachsen der Punktwolke. Darin ist der erste Vektor `Vt[0]` die Hauptachse der Datenpunkte, also die Achse "in der sich die Punkte am weitesten ausbreiten". Die zweite Achse liegt dann orthogonal auf der Hauptachse @pca (S. 434ff). Es wird die erste Hauptachse genutzt, um die "Richtung" der Punktwolke zu finden, die dann zum konstruieren der fusionierten Linie benutzt werden kann. die Punkte aus der Punktewolke werden jetzt entlang der Hauptachse projeziert und anschließend die Extrema $P_1$ und $P_2$ der Projektion gespeichert. Diese werden nun mit der Formel $p = "mean" + m*s$ also $P_"2d_max" = "mean" + m*P_1$ und $P_"2d_min" = "mean" + m*P_2$ zurück in den 2D-Raum gerechnet. Das sind dann die Punkte der fusionierten Linie. Diese fusionierte Linie wird nun einem Ergebnisarray angehangen.

=== Winkelfilter
Um einen weiteren Filter zu konzipieren, der die Menge an Linien, die zur Detektion von Haltelinien in Betracht fallen, minimiert, muss die Hauptausrichtung aller Haltelinien beachtet werden. Diese sind relativ zum Fahrzeug in erster Linie stets vertikal oder horizontal (TODO später auf Kurven verlinken). Somit ist es sinnvoll, einen Filter zu implementieren, der Linien anhand ihrers Winkels ausschließen kann.

Der Winkelfilter iteriert über eine Menge an Linien und berechnet durch den Winkel des Differnenzvektors des Start- und Endpunkts der Linie die Ausrichtung eben dieser. Dieser Winkel wird nun normalisiert und daraufhin getestet, ob dieser innerhalb einer Toleranz um 90 Grad bzw. 0 Grad liegt. Die Linien werden als zwei Listen `horiz` und `vert` zurückgegeben.

=== Pipeline für die Linienvorverarbeitung

Die Linienvorverarbeitung folgt einer festen Pipeline mit vier Filterschritten. Diese werden nacheinander auf die erkannten Linien angewendet, um die Menge an irrelevanten oder fehlerhaften Linien zu reduzieren:

#let preprocessing-diagram = align(center)[#diagram(
  spacing: 8pt,
  cell-size: (8mm, 8mm),
  edge-stroke: 1pt,
  edge-corner-radius: 3pt,
  mark-scale: 60%,
  
  node((0, 0), [Linien], width: 20mm, fill: rgb("#ff89f7").lighten(60%), stroke: 1pt + rgb("#ff89f7").darken(20%), shape: shapes.hexagon.with()),
  edge((0, 0), (1, 0), "->"),
  
  node((1, 0), [Längen Filter], width: 20mm, fill: rgb("#ffff59").lighten(60%), stroke: 1pt + rgb("#ffff59").darken(20%), corner-radius: 3pt),
  edge((1, 0), (2, 0), "->"),
  
  node((2, 0), [ROI-Filter], width: 20mm, fill: rgb("#ffff59").lighten(60%), stroke: 1pt + rgb("#ffff59").darken(20%), corner-radius: 3pt),
  edge((2, 0), (3, 0), "->"),
  
  node((3, 0), [Linien-fusion], width: 20mm, fill: rgb("#ffff59").lighten(60%), stroke: 1pt + rgb("#ffff59").darken(20%), corner-radius: 3pt),
  edge((3, 0), (4, 0), "->"),
  
  node((4, 0), [Winkel-Filter], width: 20mm, fill: rgb("#ffff59").lighten(60%), stroke: 1pt + rgb("#ffff59").darken(20%), corner-radius: 3pt),
  edge((4, 0), (5, 0), "->"),
  
  node((5, 0), [Gefiltert], width: 20mm, fill: rgb("#50dd96").lighten(60%), stroke: 1pt + rgb("#50dd96").darken(20%), shape: shapes.hexagon.with()),
)]

#figure(
  caption: [Pipeline für Linienvorverarbeitung und Filterung],
  preprocessing-diagram
) <pipeline-preprocessing>

Durch Testen dieser Pipeline haben sich außerdem einige Verbesserungsmöglichkeiten ergeben, die auch in die Pipeline integriert werden. So ist zu beobachten, dass durch Widerholung der Fusionsschritte, zuerst mit einer höheren Winkeltoleranz (15 Grad) und Abstandstoleranz (100 Pixel) und danach mit einer geringen Winkeltoleranz (5 Grad) und höherer Abstandstoleranz (120 Pixel) repräsentativere Linien erzeugt werden können.

Es wurde auch das dreifache Fusionieren getestet, welches aber im Vergleich zu der zusätzlichen Laufzeit keine Verbesserungen, sondern eher Verschlechterungen zur Linienqualität gebracht hat.

== Haltelinienklassifikation
Nach der Linienvorverarbeitung liegt nun eine Menge an Linien vor, die für die korrekte Detektion der Haltelinien in Frage kommen. Zuerst wird festgelegt, welche Haltelinien gesucht werden. Diese sind:
1. Haltelinie der eigenen Fahrspur (Egolinie)
2. Haltelinie der gegenüberliegenden Fahrspur (Opp-Linie für `opposing lane`)
3. Rechte Haltelinie
4. Linke Haltelinie
Es muss auch die Position und die Art der Linie bestimmt werden. Jede Linienart kann sowohl als durchgezogene Linie, als auch als gestrichelte Linie vorliegen.

=== Primitive Ermittlung der Ego- und Opplinie <prim>
In einem ersten Schritt liegt es nah, die Haltelinie der eigenen Spur zu detektieren. Diese erlaubt es dem Fahrzeug während der Caudri-Challenge rechtmäßig zum Halt zu kommen und gegebenenfalls andere Linien zu detektieren.

Als erster Ansatz wird die Methode gewählt, die Linie als Egolinie zu klasifizieren, die in ihrer Position am nächsten zum Fahrzeug ist und eine horizontale Ausrichtung hat. Um dies umszusetzen, wird der bereits implementierte Winkelfilter genutzt. Durch diesen erhalten wir eine Menge an Linien `horiz`, die alle horizontalen Linien in der Region of Interest darstellen. Nun wird über alle in dieser Menge enthaltenen Linien iteriert und diese dabei nach der Entfernung zur Mitte der untersten ROI Kante sortiert. Die Linie, die den geringsten Abstand aufweist, ist die Egolinie. Nach einer analogen Logik wird nun auch die Opplinie ermittelt, in dem nach der Linie mit geringsten Abstand zur oberen ROI kannte gesucht wird.

TODO Bild einfügen

Diese vorgestellte Methode liefert zufriedenstellende Ergebnisse in Kreuzungen, in denen nur eine Ego- und Opplinie vorhanden sind. Außerdem sollten die Lichtverhältnisse so ausgelegt sein, dass der LSD keine weiteren Linien erkennt, die um die Ego- oder Opplinie herumliegen. Ist dies der Fall, werden Linien falsch klassifiziert. Neben der genannten Schwäche nutzt diese Methodik nicht die allgemeine Struktur einer Kreuzung aus. Innerhalb dieser liegen alle Haltelinien in einem bestimmten, leicht variablen Abstand von einander innerhalb der Kreuzung. Die Kreuzung selbst kann als ein Quadrat interpretiert werden, welches entweder eine Kante (Halteline) oder keine Kante besitzen kann. Die Richtung, in der Spuren in die Kreuzung hineinfließen, ist mit Ausnahme der eigenen Spur, für die Kreuzungsklassifikation nicht relevant.

Mit Blick auf diese Erkentnisse wird eine neue Methodik entwickelt, die es erlaubt, zuverlässiger die Ego- und Opplinie zu erkennen.

=== Kreuzungsmittenbasierte Detektion
TODO: Verweis zu Zentrumsberechnung einfügen
Die Struktur einer Kreuzung legt nah, dass Haltelinien stets relativ zueinander in einer ähnlichen Position liegen, die in @prim beschrieben ist. Auf Basis dieser Idee wird nun die Kreuzungsmitte genutzt, um Haltelinien zu detektieren.

In einem ersten Versuch, die Kreuzungsmitte zur Detektion der Haltelinien zu nutzen, wird anstatt der Kanten der ROI nun die Kreuzungsmitte als Anhaltspunkt für Abstandsberechnungen genutzt. Demnach sind die Linien Ego- und Opplinie, die am nächsten zur Kreuzungsmitte liegen.

TODO: irgendwann auch den Winkel der Linien erklären (prominent angle) und dazu auch die clip region

Diese Methodik weist gegenüber der primitiven Methodik einige wichtige Verbesserungen auf. Die wichtigste Verbesserung ist, dass die Erkennung nun nicht darauf gestützt ist, dass der Bildausschnitt genau so auf der Kreuzung liegt, dass Ego- und Opplinie die nächsten Linien zur ROI Unter- bzw. Oberkante sind. Das ist vor allem der Fall, wenn das Fahrzeug noch weiter von der Kreuzung entfernt ist oder der LSD eine Linie erkennt, die zwischen einer der ROI Kanten und der tatsächlichen Kreuzung liegt. Durch diese Methodik wird nun auch die Struktur einer Kreuzung ausgenutzt, in der Haltelinien relativ zueinander immer gleich angeordnet sind. Dies erzeugt eine robustere Halteliniendetektion.

=== Sektorbasierte Detektion der rechten und linken Haltelinie
Nachdem nun vorerst die Egolinie und die Opplinie erkannt werden, ist es wichtig, auch die Haltelinien der Spur, die von Egoausrichtung rechts in die Kreuzung einmündet und die Haltelinie der Spur links zu detektieren. Die Idee der Kreuzungsmitte legt nah, dass diese auch zur Detektion der rechten und linken Haltelinie genutzt werden kann. Man berechne die vertikalen Linien, die am nächsten am Kreuzungszentrum sind. In der Entwicklung ist man nun aber mit der Schwierigkeit konfrontiert, dass die Kreuzungsmitte nicht zuverlässig perfekt zentral platziert ist. Dies hat zur Folge, dass oft Linien, die tatsächlich zur Spur gehören, als Haltelinien erkannt werden.

==== Dreieckssektor
Aufgrund dieser Tatsache wird eine Methodik vorgestellt, die zwei dreieckige Sektoren nutzt, die innerhalb der ROI rechts und links platziert werden, um entsprechende Haltelinien zu finden. TODO: Bild einfügen. Diese Sektoren bestehen aus einem nach oben geöffneten Dreieck für die rechte Haltelinie und einem nach unten geöffneten Dreieck für die linke Haltelinie. Die Dreiecksstrukur ist darin begründet, dass bei minimalem Lenken des Fahrzeugs die Querhaltelinien in x-Position teilweise nach rechts oder links verschoben sein können.

Innerhalb des Sektors wird nun die Linie als Haltelinie ausgewählt, die am längsten ist.

Ein Problem dieser Sektorform ist, dass die Fläche, in der die Haltelinie gesucht wird, zur Grundseite des Dreiecks am größten ist. Das bewirkt, dass die Suchfläche (beispielsweise für die rechte Haltelinie) größer ist, je weiter die Kreuzung vom Fahrzeug entfernt ist. Das führt dazu, dass die tatsächliche Haltelinie nicht innerhalb der Suchregion liegt, wenn das Fahrzeug an der Kreuzung steht.

==== Trapezförmiger Sektor
Um dem Umstand entgegenzuwirken, dass die Querhaltelinien nicht in der Suchregion liegen, wird der Sektor zu einer Trapezform geändert. Diese werden auf der rechten und linken Seite der ROI platziert. Diese Änderung hat zur Folge, dass der Suchbereich in der Mitte der Höhe der ROI am größten ist. Steht das Fahrzeug nun vor der Kreuzung, soll die Haltelinie theoretisch innerhalb des Sektors liegen.

TODO: Bild??

Nach weiteren Überlegungen und Tests wird auch dieser Ansatz verworfen, da statische Formen innerhalb der ROI, in denen die Haltelinien theoretisch zu erwarten sind, nicht zuverlässig funktionieren. Je nach Kalibrierung der Kamera und Anfahrt auf die Kreuzung, müssten sich die Sektoren in ihrer Position verändern.

==== Quadrantenbasierte Suche
Die ROI wird nun in vier Quadranten unterteilt, die von Q1 bis Q4 (1 - oben links, 2 - oben rechts, 3 - unten links, 4 - unten rechts) nummeriert sind. Innerhalb dieser Quadranten wird nun die rechte Haltelinie im Quadranten zwei oder im Quadranten 4 erwartet. Die linke Haltelinie wird im Quadranten eins erwartet. Der Quadrant drei wird für die linke Haltelinie nicht in Betracht gezogen, da durch die Kameraperspektive in diesen Quadranten keine nutzbaren Informationen (also kein nutzbares Bild) abgebildet sind.

Mit Hilfe der Quadrantenbasierten Suche gelingt es, Querhaltelinien zu erkennen.

TODO: wie und wann Sprung auf BEV erklären

=== Zentrumsbasierte Detektion aller Haltelinien
Die vorgestellten Methoden zur Detektion der rechten und linken Haltelinien weisen bei Kreuzungsanfahrt aus Kurven oder bei falsch detektierten Linien enorme Defizite auf.

Aufgrund dieses Umstands werden auch die Querhaltelinien auf Basis des Kreuzungszentrums berechnet. Es bleibt jedoch die Schwierigkeit, dass die aus dem Bilddaten berechnete Position des Kreuzungszentrums nicht exakt mit der tatsächlichen Position des Kreuzungszentrums übereinstimmt. Um, diesem Problem entgegenzuwirken, werden die aus dem Kreuzungszentrum abgeleiteten Referenzpunkte (TODO Kapitel referenzieren) genutzt. Mit Hilfe dieser Referenzpunkte ist es möglich, eine zuverlässige Detektion aller Haltelinien aus der Menge der vorverarbeiteten Linien durchzuführen.

Es wird auch die Hauptspurausrichtung genutzt, um die Referenzpunkte so zu berechnen, dass die Referenzen für die Ego- und Opplinie in Richtung des Spurwinkels liegen und die Referenzpunkte für die rechte und linke Haltelinie orthogonal dazu liegen (siehe dazu @ghostcc).

== Berechnung des Kreuzungszentrums
Die Struktur der Kreuzungen innerhalb der Caudri-Challenge können zur verbesserten Detektion von Haltelinien ausgenutzt werden. Demnach liegen die Haltelinien jeder Kreuzung stets auf den Kanten eines Quadrats, dessen Ecken die Punkte sind, an denen die Spuren zur Kreuzung zusammenkommen.

=== Primitive Bestimmung der Kreuzungsmitte
Als erster Schritt liegt es nah, die Kreuzungsmitte als Zentrum der ROI festzulegen. Dies ist tatsächlich hilfreich, da es ein erster Schritt ist, die Struktur der Kreuzung auszunutzen und nicht Abstandsberechnung zu den Kanten der ROI zu nutzen. Allerdings weist diese Methodik das Problem auf, dass die Korrekten Haltelinien nur richtig erkannt werden, wenn das ROI-Zentrum gerade innerhalb der tatsächlichen Kreuzung liegt. Ist das Fahrzeug noch weiter von der Kreuzung entfernt oder ist schon zu Teilen in die Kreuzung hineingefahren, kann es dazu kommen, dass Linien außerhalb der Kreuzung als Haltelinien klassifiziert werden.

=== Algorithmische Kreuzungsmittendetektion
Bei weiterer Überlegung, die tatsächliche Kreuzungsmitte zu berechnen, wird ersichtlich, dass mehr Bildinformationen genutzt werden können, um das Zentrum verlässlicher zu berechnen.

Es ist denkbar, die Schnittpunkte der Spurlinien zu berechnen und daraufhin daraus das Kreuzungszentrum abzuleiten. Da bisher kein Ansatz ausgearbeitet wurde, um die Spuren aus dem Kamerabild zu berechnen, muss zuerst festgelegt werden, welche der Linien aus der gesamten Linienmenge potentielle Spuren sind.

==== DBSCAN
Ein Ansatz, um Spurlinien zu erkennen und daraufhin die Kreuzungsmitte zu berechnen, ist der `DBSCAN` Algorithmus. 

Der Algorithmus beruht auf der Idee, aus einem mehrdimensionalen Datensatz so genannte `Cluster` (dt. Haufen) an Datenpunkten zu finden, wobei die clusterinterne Ähnlichkeit maximiert und die Ähnlichkeit zwischen den Clustern minimiert werden soll @dbscan (S. 232). Ein Clustering Algorithmus wird dann als effektiv angesehen, wenn er viele der folgenden Kriterien abdeckt @dbscan (S. 232):
- Der Entwickler braucht minimale Domänenkenntnisse, um den Algorithmus zufriedenstellend zu parametrieren
- Der Algorithmus erkennt Cluster beliebiger Form
- Der Algorithmus arbeitet effizient, auch bei großen Datensätzen
Für den vorliegenden Anwendungsfall sind diese Kriterien auch wichtig, da der `DBSCAN` Algorithmus genutzt werden soll, um aus hellen Pixeln, die als Datenpunkte interpretiert werden, Cluster zu finden, die dann die Spuren darstellen.

Die Hauptidee des Algorithmus ist, dass jeder Punkt $P$ einen anderen Punkt $K$ innerhalb eines Radius $epsilon$ um den Punkt aufweist. Durch dieses Kriterium ergibt sich ein so genannter `Core Point`. Dieser wird wie folgt beschrieben:
#figure(
  $N_"eps" (P) > "MinPts"$,
  caption: "DBSCAN Core Point Kriterium"
)
Die Parameter `eps` und `MinPts` können hierbei vom Anwender gewählt werden. `Eps` stellt dabei den Radius dar, in dem eine Mindestanzahl `MinPts` an anderen Datenpunkten gefunden werden soll, damit $P$ als `Core Point` klassifiziert wird. Der Algorithmus fährt dann fort und fügt jedem `Core Point` Datenpunkte aus der Umgebung zu. Wenn jedem Cluster kein neuer Punkt mehr hinzugefügt werden kann, terminiert der Algorithmus @dbscan (S. 233).

Innerhalb der Berechnung des Kreuzungszentrums soll der DBSCAN Algrithmus verwendet werden, um durch Clustering Linien zu bilden. Es stellt sich die Frage, ob anstatt des DBSCAN Algorithmus bereits verfügbare Linien genutzt werden können, die der `Line Segment Detector` berechnet. Der LSD weist dabei ein Problem auf, was durch den DBSCAN behoben werden kann, undzwar, dass Linien oft fragmentiert sind und dadurch keine eindeutige Kreuzung der Linien berechnet werden kann.

Nachdem Cluster berechnet wurden, kann durch PCA (TODO: Referenz hinzufügen), eine Menge an Linien gewonnen werden, die danach miteinander gekreuzt werden. Der Mittelpunkt aller Kreuzungen ist dann die Kreuzungsmitte.

Durch Testing in der Pipeline hat sich dieser Ansatz zwar als generell sinnvoll, aber nicht optimal herausgestellt. Da durch Fusionierung in der Vorverbeitung bereits aus sehr kleinen Segmenten repräsentative Linien berechnet wurden, werden die weiteren Rechenkosten des DBSCAN als nicht gerechtfertigt angesehen. Zudem wies dieser Ansatz bei Anfahrt aus Kurven, in weiterer Entfernung von der Kreuzung und bei Mangel an erkannten Linien starke Mängel auf und berechnete die Kreuzungsmitte teilweise außerhalb der Kreuzung, was zu vollständig falschen Klassifikationen führte. Um den Parametrierungsaufwand zu minimieren, wurden vorerst weitere Ansätze getestet.

==== Kreuzung von LSD-Linien
Um den Berechnungsaufwand durch DBSCAN zu umgehen, stellte sich der Ansatz, Linien aus der Vorverarbeitung zu nutzen, als sinnvoll dar. Demnach könne man eben diese Linien miteinander kreuzen und dann den Kreuzungsmittelpunkt berechnen.

TODO: ausführen bzw was schreibe ich hier rein
Vielleicht sogar nochmal ausprobieren?? Sonst auslassen??

==== Harris Corner Detection

Ein anderer Ansatz ist es, ohne Linien zu kreuzen innerhalb des Bildes Ecken zu detektieren und durch Mitteln aller Ecken das Kreuzungszentrum zu finden. Ein etablierter Algorithmus zur Detektion von Ecken ist der `Harris Corner Detector`.

Der Harris Corner Detector ist ein klassischer Eckenerkennung-Algorithmus, der 1988 von Chris Harris und Mike Stephens entwickelt wurde. Der Algorithmus identifiziert Punkte im Bild, an denen sich die Bildintensität in mehreren Richtungen stark ändert – typischerweise an Ecken oder anderen strukturierten Features.

Der Algorithmus berechnet zunächst die Gradienten des Bildes in horizontale und vertikale Richtungen. Für jeden Pixel wird dann eine Auto-Korrelations-Matrix (auch Struktur-Tensor genannt) berechnet, die misst, wie sich die Bildintensität in verschiedenen Richtungen ändert. Basierend auf dieser Matrix wird eine Eckenresponse-Funktion berechnet: $R = lambda_1 lambda_2 - k (lambda_1 + lambda_2)^2$, wobei $lambda_1$ und $lambda_2$ die Eigenwerte der Matrix sind und $k$ ein Tuning-Parameter (typischerweise 0.04–0.06) ist. Pixel mit hohem Response-Wert werden als Eckenpunkte klassifiziert. Der Schwellwert wird meist empirisch gesetzt.

Ein großer Vorteil des Harris Detectors ist seine Recheneffizienz und die stabile Eckenerkennung in vielen Bildern. Allerdings hat der Algorithmus einige Schwächen: Die Eckenresponse ist nicht invariant gegenüber Skalierung, was bedeutet, dass unterschiedlich große Ecken unterschiedlich bewertet werden. Außerdem ist die Wahl des Parameters $k$ kritisch und muss oft manuell angepasst werden.

==== Shi-Tomasi Eckenerkennung

Neben dem `Harris Corner Detector` gibt es außerdem den `Shi-Tomasi` Algorithmus zur Erkennung von Ecken. 

Der Shi-Tomasi Corner Detector ist eine Variante des Harris Corner Detectors, die 1994 von Jianbo Shi und Carlo Tomasi entwickelt wurde. Der Algorithmus versucht, Eckenpunkte in einem Bild zu erkennen, indem er lokale Bereiche analysiert, in denen sich die Bildintensität in mehreren Richtungen stark ändert.

Der Algorithmus funktioniert wie folgt: Zunächst wird für jeden Pixel die Auto-Korrelations-Matrix berechnet, die angibt, wie stark sich die Bildintensität in unterschiedliche Richtungen ändert. Diese Matrix wird als Struktur-Tensor oder Harris-Matrix bezeichnet. Anstatt der bei Harris verwendeten Eckenresponse-Funktion nutzt Shi-Tomasi direkt die Eigenwerte dieser Matrix: Ein Pixel wird als Eckenpunkt klassifiziert, wenn der kleinere der beiden Eigenwerte größer als ein Schwellwert ist. Dies bedeutet, dass die Bildintensität in mindestens zwei Richtungen stark variiert. Ein großer Vorteil dieses Ansatzes ist, dass er das optische Fluss-Tracking-Problem besser löst, da er auf die tatsächliche Struktur der Bildänderungen reagiert, anstatt auf eine heuristische Eckenmetrik.

Der Shi-Tomasi Algorithmus ist robuster gegen Skalierung und Rotation von Features, was ihn für die praktische Anwendung attraktiver macht. Außerdem berechnet der Algorithmus sowohl die Position als auch eine Qualitätsmetrik für jeden erkannten Eckenpunkt, was eine nachträgliche Filterung und Bewertung ermöglicht.

Durch Testing in der Pipeline wird der `Shi-Tomasi` Algorithmus als Basis der Kreuzungszentrumserkennung gewählt. Die Parametrierung des Algorithmus fällt simpel aus: Es werden für die Anzahl der auszugebenden Ecken $n=4$ gewählt, sodass die repräsentativsten Ecken (die die Ecken der Kreuzung darstellen sollen) ausgegeben. Das Shi-Tomasi Zentrum ist dabei das Mittel der gefundenen Ecken.

=== Hybrider Ansatz zur Kreuzungsmittenberechnung
Obwohl `Shi-Tomasi` zufriedenstellende Ergebnisse liefert, kommt es auch zu Berechnungen von Kreuzungsmitten, die eine hohe Abweichung zum tatsächlichen Zentrum aufweisen. Um dem entgegenzuwirken, sollen Eckpunkte zuerst validiert werden, bevor ein Kreuzungszentrum berechnet wird.

Eine grundlegende Idee wäre es, zu prüfen, ob die Innenwinkelsumme der vier gefundenen Ecken $360 degree$ ist. Dieser Ansatz wird verworfen, da Eckpunkte in verschiedenen Anordnungen, die nicht unbedingt ein Viereck sein müssen, auch $360 degree$ ergeben. Stattdessen werden nun die einzelnen Winkel an den Ecken berechnet, die für ein Vierreck jeweils $90 degree$ ergeben müssen. Um eine Metrik zu gewinnen, die die Ähnlichkeit der Anordnung der Ecken zu einem Viereck darstellt, werden die jeweiligen Fehler an jeder Ecke zu $90 degree$ berechnet und dann der Durchschnitt über alle vier Ecken gebildet. Anhand dieser Metrik kann nun bestimmt werden, ob das Shi-Tomasi Zentrum genutzt wird oder nicht.

Außerdem wird zusätztlich ein Gedächtnissystem eingebaut. Wird ein valides Shi-Tomasi Zentrum gefunden, wird dieses für fünf Frames gehalten. Es ändert dann in jedem Frame seine Position um einen festgelegten Pixelwert entlang der Hauptausrichtung der Linien (TODO: referenz zu dem hauptwinkel). Dieses Tracking erzeugt selbstverständlich keine Ergebnisse, die an die eines Kalman-Filters herankommen. Da die Anzahl der Frames, die das Zentrum gespeichert wird, aber relativ klein mit Blick auf die Framerate der Kamera ist, ist diese Näherung zufriedenstellend und liefert Ergebnisse, die gut für die Detektion von Linien genutzt werden können.

Kann kein Shi-Tomasi Zentrum berechnet werden, wird weiterhin das Zentrum der ROI als Redundanz angenommen.
=== Pipeline zur Kreuzungszentrumserkennung
Aus den gesammelten Erkenntnissen ergibt sich folgende Pipeline zur Erkennung des Kreuzungszentrums.

#let corner-pipeline = align(center)[#diagram(
  spacing: 10pt,
  cell-size: (10mm, 10mm),
  edge-stroke: 1pt,
  edge-corner-radius: 5pt,
  mark-scale: 70%,
  
  node((0, 0.5), [Shi-Tomasi], width: 25mm, fill: rgb("#ffff59").lighten(60%), stroke: 1pt + rgb("#ffff59").darken(20%), corner-radius: 5pt),
  edge((0, 0.5), (1, .5), "->"),
  
  node((1, 0.5), [Plausibel?], width: 25mm, fill: rgb("#ffc559").lighten(60%), stroke: 1pt + rgb("#ffff59").darken(20%), corner-radius: 5pt),
  edge((1, 0.5), (1, 0) , "r,r", "-|>", label: "Ja"),
  
  node((3, 0), [Shi-Tomasi Mittel], width: 25mm, fill: rgb("#5090dd").lighten(60%), stroke: 1pt + rgb("#50dd96").darken(20%), corner-radius: 5pt),

  edge((3, 0), (3, 0), "<-", bend: 130deg, label: "5 Frames"),

  edge((1, 0), (1, 1), "r", "-"),
  edge((1.14, 1), (3, 1), "-|>", label: "Nein"),

  node((3, 1), [ROI Mitte], width: 25mm, fill: rgb("#5090dd").lighten(60%), stroke: 1pt + rgb("#50dd96").darken(20%), corner-radius: 5pt),

  edge((3, 0), (5, 0.5), "->"),

  edge((3, 1), (5, 0.5), "->"),

  
  node((5, 0.5), [Zentrum], width: 25mm, fill: rgb("#50dd96").lighten(60%), stroke: 1pt + rgb("#50dd96").darken(20%), corner-radius: 5pt),
  
)]

#figure(
  caption: [Pipeline für Kreuzungszentrumserkennung],
  corner-pipeline
) <pipeline-corners>


=== Erweiterung der Kreuzungsmitte <ghostcc>
Bei der Kreuzungsmittenerkennung kommt es vereinzelt zu Berechnungen von Mitten, die nicht exakt in der tatsächlichen Mitte der Kreuzung liegen. Das ist allgemein unproblematisch für die Erkennung von Haltelinien, kann aber vereinzelt dazu führen, dass Haltelinien später erkannt werden als es möglich wäre oder das System in einigen Frames Haltelinien verliert. Grund dafür ist, dass aufgrund der Logik, die nächste Linie zum Kreuzungszentrum zu suchen, falsche Linien als Haltelinien klassifiziert werden. Die tatsächliche Haltelinie und eine sehr nah an dieser liegende "kämpfen" um die Klassifikation als Haltelinie.

Um dieses Problem zu lösen, werden weitere Referenzpunkte aus der Kreuzungsmitte berechnet. Für die Ego- und Opplinie liegen diese entlang des Hauptwinkels der Linie und für die rechte und linke Haltelinie orthogonal dazu. Da die Referenzpunkte näher an dem tatsächlichen Bereich liegen, in denen die Haltelinien zu vermuten sind, werden auch die korrekten Haltelinien als diese klassifiziert. (TODO BILD)

== Klassifizierung der Linienart
Neben der Lokalisation der Haltelinien muss auch erkannt werden, um welche Art es sich bei der haltelinie handelt. Haltelinien können sowohl gestrichelt als auch durchgezogen sein.

Um dies zu bestimmen, wird ein Algorithmus implementiert, der eine Linie und das Rohbild als Input erhält und den Weißanteil der Linie als auch die Anzahl der Lücken entlang der Linie ausgibt.

=== Linienausschnitt
Zu Beginn wird die Linienmitte bestimmt. Nun wird entlang des Linienzentrums rotiert, sodass die Linie waagerecht im Bild liegt. Dafür wird folgender Code genutzt.

#code-block(
  caption: [Rotation des Bildes um das Linienzentrum],
  ```python
  h, w = image.shape[:2]
  M = cv2.getRotationMatrix2D((mid_x, mid_y), angle, 1.0)
  warped = cv2.warpAffine(image, M, (w, h), flags=cv2.INTER_LINEAR)
  ```,
  highlight-lines: (
    (2, [Die Linienmitten und der Linienwinkel wurden vorher berechnet]),
  )
) <warp-line>

Die Funktion `cv2.getRotationMatrix2D` berechnet dabei eine Rotationsmatrix mit der außerdem eine Verschiebung möglich ist. Das ist nötig, da nicht um den Ursprung rotiert wird. Eine Rotationsmatrix um den Ursprung sieht wie folgt aus.
#figure(
  $
    R = mat(cos(theta), -sin(theta);
    sin(theta), cos(theta)) 
  $
)
Da nun aber nicht um den Ursprung, sondern durch einen beliebigen Punkt im Bild rotiert wird die Matrix um konstante Werte erweitert, anhand derer alle Punkte um einen beliebigen Punkt im Bild verschoben werden können.
#figure(
  $
    R = mat(cos(theta), -sin(theta), t_x;
    sin(theta), cos(theta), t_y;
    0, 0, 1)
  $
)
Nun wird das Zentrum der ursprünglichen Linie in deas rotierte Bild transformiert.

Jetzt wird der Ausschnitt um die Linie aus dem rotierten Bild ausgeschnitten. Der Ausschnitt wird so ausgeschnitten, dass sowohl zu den Seiten als auch oben und unterhalb der Linie Abstand besteht. (TODO BILD einfügen)

=== Weißwertberechnung
Es ist unabdinglich, in verschiedenen Lichtverhältnissen zuverlässig den Weißwert der Linie berechnen zu können. Die Annahme ist, dass neben den weißen Pixeln des Ausschnitts auch graue oder nahezu weiße Pixel um den Linienabschnitt selbst liegen können. Dies kann etwa durch Sonneneinstrahlung passieren.

Um dem entgegenzuwirken, wird der Ausschnitt vorverarbeitet. Um das Bild unabhängig von Lichtverhältnissen nutzbar zu machen, müssen graue bis weiße Bildbereiche, die aber nicht zur Linie gehören, unterdrückt werden. Dafür wird zuerst der `Canny`-Algorithmus verwendet, um Pixel zu finden, die tatsächlich zur Linie gehören könnten. Daraus wird eine Pixelmaske generiert, die anschließend genutzt wird, um die originalen Pixelwerte der Pixel aus dem Bildabschnitt auszulesen. Es wird der Median dieser Pixelwerte gebildet. Falls der Canny-Algorithmus kein Ergebnis geliefert hat, wird der Median des ganzen Ausschnitts berechnet.

Der Ansatz, um für die Berechnung interessante Pixel, also die Pixel, die tatsächlich zur Linie gehören, gegenüber Hintergrundpixeln hervorzuheben, besteht in einer Verschiebung der Pixelwerte mit der Sigmoid-Funktion.
Diese ist wie folgt beschrieben:
#figure(
  $
    sigma(x) = frac(1, 1 + e^(-x))
  $,
  caption: "Sigmoid Funktion"
)
Mit der Sigmoidfunktion wird nun eine konstrastverstärkenden, nicht lineare Normalisierung der Pixelwerte innerhalb des Ausschnitts durchgeführt. Dafür werden zuerst die Pixelwerte normalisiert, indem sie zuerst um den Medianwert verschoben und dann durch 50 dividiert werden. Die Division hat den Hintergrund, dass die Sigmoid Funktion nur etwa im Bereich $+-3$ effektiv normalisiert (siehe @sigmoid-plot). Das heißt, dass eine Intensitätsänderung um $+-150$ zu einer vollständigen Sättigung in der Sigmoidfunktion führt, was für die Pixelwerte `0-255` gut passt.

#figure(
  canvas({
    plot.plot(
      size: (7, 3),
      axis-style: "scientific",
      x-label: $x$,
      y-label: $sigma(x)$,
      x-min: -5,
      x-max: 5,
      y-min: 0,
      y-max: 1,
      {
        plot.add(
          style: (stroke: (paint: blue, thickness: 2pt)),
          domain: (-5, 5),
          (x) => 1 / (1 + calc.exp(-x)),
        )
      }
    )
  }),
  caption: [Visualisierung der Sigmoid-Normalisierungsfunktion]
) <sigmoid-plot>

Nun werden durch die Sigmoidfunktion Intensitätswerte, die nah am Median liegen in Richtung der 0.5 normalisiert. Werte, die weiter unter dem Median liegen, werden in Richtung 0 normalisiert. Werte über dem Median in Richtung 1 (@sigmoid-plot).
Jetzt werden die berechneten Werte wieder mit Faktor 255 skaliert.

Im nächsten Schritt wird adaptives Thresholding genutzt, um die tatsächliche Segmentierung der Linie vom Hintegrund durchzuführen. Durch das adaptive Thresholding wird noch einmal sichergestellt, dass Lichtinvarianzen nicht ins Gewicht fallen und das Liniensegment sicher erkannt wird, da es keinen globalen Threshold für ein Bild ermittelt. Das adaptive Thresholding nutzt lokale Thresholdermittlung für jeden Pixel.

Es werden nun gewonnene Informationen in einer einzigen Bitmaske zusammengefasst, die einen Minimalintensitätswert für die Linienpixel vorraussetzt, die aber auch durch das adaptive Thresholding als zur Linie zugehörig klassifiziert wurden.

#code-block(
  caption: [Bitmaske des Liniensegments für die Weißanteilberechnung],
  ```python
binary = (gray >= 60).astype(np.uint8) & adaptive_binary
  ```,
  highlight-lines: (
  )
) <wrcalc-binary>

Nun wird das Bild in ein 1D Spaltenprofil umgewandelt, indem die Anzahl der weißen Pixel in jeder Spalte summiert werden (TODO: auch hier ein Bild einfügen). Mit Hilfe dieses Wertes und der Gesamtgröße des Ausschnitts wird nun der Weißanteil der Linie am Ausschnitt berechnet. Dieser Wert kann zur Validierung von Linien verwendet werden. Detektierte Linien, die tatsächlich aber nicht auf realen Linien liegen, weisen dabei einen sehr geringen Weißanteil im Ausschnitt auf und können somit ausgefiltert werden. 
=== Gap-Detektion
Um zu bestimmen, ob es sich bei Linien um gestrichelte oder durchgezogene Haltelinien handelt, werden die Lücken zwischen den weißen Teilen einer Linie berechnet. Im Schritt zuvor wurde ein Spaltenprofil des Ausschnitts angelegt, welches die Anzahl weißer Pixel pro Spalte aufsummiert anzeigt. Dieses Profil wird nun genutzt. Dabei werden die Spalten nach folgendem Algorithmus berechnet @gap-algo.
#figure(
  caption: "Lückenerkennungsalgorithmus",
    pseudocode-list[
      + Iteriere über die Spalten *i* des Spaltenprofils
        + Falls Wert bei *i* (Summe der weißen Pixel) == 0:
          + Falls bereits in einer Lücke, *gap_size*++
          + Falls noch in keiner Lücke
            + Setze *in_gap* auf 1
        + Falls Wert bei *i* > 0
          + Falls *in_gap* == 1 & *gap_size* > *min_gap_size*
            + *gaps*++
          Setze *in_gap* auf 0 und resette *gap_size*
      + Falls nach Beenden der Schleife noch *in_gap* == 1, inkrementiere Gap-Anzahl
      + Gebe *gaps* zurück
  ]
) <gap-algo>

Schließlich wird über einen Parameter `min_gap_count` bestimmt, wann eine Linie gestrichelt ist. Durch Tests hat sich `min_gap_count=3` als optimaler Parameter für die Funktion ergeben.

=== Pipeline zur Klassifizierung der Linienart

Nachdem nun die algorithmische Basis der Klassifizierung der Linienart näher eläutert wurde, wird nochmal eine Übersicht über die genutzte Pipeline innerhalb des Moduls gegeben.

#let lineart-pipeline = align(center)[#diagram(
  spacing: 2pt,
  cell-size: (9mm, 7mm),
  edge-stroke: 1pt,
  edge-corner-radius: 5pt,
  mark-scale: 70%,
  
  node((0, 4), [Bild], width: 22mm, fill: rgb("#ff89f7").lighten(60%), stroke: 1pt + rgb("#ff89f7").darken(20%), shape: shapes.house),
  edge((0, 4), (0, 2), "-|"),

  node((0, 2), [Rotation], width: 22mm, fill: rgb("#21de13").lighten(60%), stroke: 1pt + rgb("#59ffb2").darken(20%), corner-radius: 3pt),
  edge((0, 2), (0, 1), "-|"),

  node((0, 1), [Canny], width: 22mm, fill: rgb("#21de13").lighten(60%), stroke: 1pt + rgb("#59ffb2").darken(20%), corner-radius: 3pt),
  edge((0, 1), (0, 0), "-|"),
  
  node((0, 0), [Sigmoid], width: 22mm, fill: rgb("#21de13").lighten(60%), stroke: 1pt + rgb("#59ffb2").darken(20%), corner-radius: 3pt),

	edge((0, 0), (0, -0.40), "r", (1,3), "r,u", "-|>"),
  
  node((2, 2), [Thresholding], width: 30mm, fill: rgb("#21de13").lighten(60%), stroke: 1pt + rgb("#59ffb2").darken(20%), corner-radius: 3pt),
  edge((2, 2), (2, 0.5), "-|"),
  
  node((2, 0.5), [Spaltenprofil], width: 30mm, fill: rgb("#32bfd8").lighten(70%), stroke: 1pt + rgb("#59b4ff").darken(20%), corner-radius: 3pt, shape: shapes.hexagon),
	edge((2, 0.5), (2, 0), (2.9, 0), (2.9,1.3), (3.2, 1.3),  "-"),

  edge((3.2, 1.3), (3.4, 1.3), (3.4, 0.65), (3.7, 0.65), "-|>"),
  edge((3.2, 1.3), (3.4, 1.3), (3.4, 2.15), (3.7, 2.15), "-|>"),
  
  node((4.6, 0.65), [Weißanteil], width: 30mm, fill: rgb("#ff5959").lighten(60%), stroke: 1pt + rgb("#ff5959").darken(20%), corner-radius: 3pt),
  
  node((4.6, 2.15), [Gap-Detekt.], width: 30mm, fill: rgb("#ff5959").lighten(60%), stroke: 1pt + rgb("#ff5959").darken(20%), corner-radius: 3pt),

  edge((5.5, 0.65), (5.7, 0.65), (5.7, 1.3), (6.1, 1.3), "-|>"),
  edge((5.5, 2.15), (5.7, 2.15), (5.7, 1.3), (6.1, 1.3), "-|>"),

  node((6.85, 1.3), [Bedingung], width: 15mm, fill: rgb("#9659ff").lighten(60%), stroke: 1pt + rgb("#a959ff").darken(20%), corner-radius: 3pt, shape: shapes.chevron),
  edge((6.85, 1.3), (9, 1.3), "-|>"),

  node((9, 1.3), [Linienart], width: 22mm, fill: rgb("#ffd859").lighten(60%), stroke: 1pt + rgb("#ffec59").darken(20%), corner-radius: 3pt),
)]

#figure(
  caption: [Pipeline für die Klassifizierung der Linienart],
  lineart-pipeline
) <pipeline-lineart>


== Heading der Straße 

Ein bisher beständiges Problem der Kreuzungserkennung ist die falsche oder ausgelassene Detektion von Haltelinien bei Anfahrt aus einer Kurve. Zusätzlich hängt die Ausrichtung der abgeleiteten Kreuzungsmitten (TODO ref) auch von der Orientierung der Straße ab und ändert sich deshalb bei Anfahrt aus Kurven.

=== Gaussian Mixture Model mit Expectation Maximization
Eine verwandte Methode zur Bestimmung der Straßenorientierung ist die Lenkwinkelberechnung für autonome Fahrzeuge. Ein vielversprechender Ansatz, der in der Literatur beschrieben wird, nutzt Computer Vision mit geringen Rechenkosten. Die Methode basiert auf drei Schritten: Zunächst wird die befahrbare Straßenregion mittels Gaussian Mixture Model (GMM) mit Expectation Maximization (EM) extrahiert, um robust mit Schatten und verschiedenen Lichtverhältnissen umzugehen. Daraufhin werden die Straßengrenzen durch Canny Edge Detection detektiert. Abschließend wird der Lenkwinkel aus dem Schnittpunkt der extrahierten Grenzen berechnet – also dem Punkt, in dem sich die extrapolierten Straßenkanten treffen. Der Winkel zwischen diesem Schnittpunkt und der Fahrtmitte ergibt dann die erforderliche Fahrtrichtung. Zur Rauschunterdrückung werden Kalman-Filter eingesetzt, um abrupte Lenkwinkeländerungen durch Fahrbahnunebenheiten oder Umgebungsrauschen zu glätten @gnnem.

Dieser Ansatz ist interessant für die Kreuzungserkennung, da die Straßenorientierung direkt aus dem aktuellen Kamerabild ermittelt werden kann, ohne zusätzliche Sensoren wie LIDAR oder RADAR zu benötigen. Die Methode funktioniert auch auf unstrukturierten Straßen und unter verschiedenen Lichtverhältnissen, was für realistische Einsatzszenarien vorteilhaft ist @gnnem.

Für den vorliegenden Anwendungsfall ist die Methodik nutzbar, erscheint aber aufgrund der bereits berechneten Liniensegmente in ihrem Umsetzungsaufwand zu groß.

=== Deep Learning basierter Ansatz
Neben dem zuvor vorgestelleten Computer Vision basierten Algorithmjs zur Berechnung des Heading Winkels gibt es auch zahlreiche Methodiken, die auf Basis von trainerten Modellen arbeiten. Beispielsweise können die Convolutional Neural Networks (CNN) sein @dlsteering. Dafür muss ein großer Datensatz akquiriert und annotiert werden, bevor ein neuronales Netz zu trainieren. Dieses kann dann auf Basis der Trainingsdaten den Heading Winkel auf Realdaten vorraussagen @dlsteering.

Auch dieser Ansatz erscheint für den vorliegenden Anwendungsfall unpassend, da er eine Akquise eines annotierten Trainingsdatensatzes vorraussetzt. Außerdem ist ein Ansatz mit geringeren Rechenkosten möglich.

=== Histogrammbasierter Ansatz
Im Folgenden wird ein weiterer Ansatz erläutert, der auf der Berechnung des Heading Winkels über Histogramme aller erkannten Linien basiert.

Dafür werden in einem ersten Schritt Linien nach ihrer Ausrichtung sortiert. Dabei werden nur Linien zur Berechnung des Winkels genutzt, die im Winkelbereich $45 degree <= alpha <= 135 degree$ liegen. 

Nun wird aus den Winkeln aller validen Linien ein Array erstellt, welches zum erstellen eines Histogramms genutzt wird. Die Grundidee ist es, die dominante Ausrichtung der Linien im aktuellen Bild zu finden. Dafür wird folgender Code verwendet.

#code-block(
  caption: [Berechnung eines Histogramms über Winkel der Spurlinien],
  ```python
  valid_angles_arr = np.array(valid_angles)
  bins, range = 18, (45, 135)
  hist, bin_edges = np.histogram(valid_angles_arr, bins=bins, range=range)
  peak_bin = int(np.argmax(hist))
  prominent_angle = float((bin_edges[peak_bin] + bin_edges[peak_bin + 1]) / 2.0)
  ```,
  highlight-lines: (
  )
) <heading>
TODO: CODE ÄNDERN IN DER REPO (WENIGER BINS UND ANDERE RANGE)

In einem ersten Schritt wird ein Histogramm aus 18 Bins in einem Bereich von `(45, 135)` erstellt. Dadurch ist eine Auflösung von $frac(135 degree - 45 degree, 18) = 5 degree$ festgelegt. Diese ist grob gewählt, da durch die Fusion der Linien in der Vorverarbeitung eine relativ geringe Anzahl an Linien für die Histogrammbildung in Frage kommt. Es wird nach der Histogrammbildung die Bin mit den größten Anzahl an Elementen ausgewählt. Dies ist die dominante Ausrichtung aller vertikalen Linien im aktuellen Bild. Dadurch, dass der Bereich mit $[45; 135]$ festgelegt wird, kann der dominante Winkel folglich auch nur in diesem Bereich liegen. Das ist aber für den Anwendungsfall sinnvoll, da das Fahrzeug im Normalbetrieb mit einem Heading-Winkel fährt, der nicht außerhalb dieses Bereichs fällt. Wäre dies der Fall, würde eine Situation vorliegen, in der das Fahrzeug nicht korrekt auf der Straße platziert oder von dieser abgekommen ist. In diesem Fall wäre die Kreuzungserkennung deaktiviert.

Zuletzt wird der Durchschnitt des Bins `peak` und des Bins `peak + 1` berechnet. Dies ist der Tatsache geschuldet, dass die Peakbin nur den unteren Rand des tatsächlichen Ergebnisses abbildet und die Bin `peak + 1` den oberen Rand. Der Durchschnitt dieser approximiert den tatsächlichen Winkel.

=== Pipeline zur Headingwinkel Berechnung

Aus der nun beschriebenen Methodik ergibt sich folgenden Pipeline, die innerhalb des Systems zur Approximierung des Heading Winkels verwendet wird (@pipeline-heading). Es wird der histogrammbasierte Ansatz gewählt, da dieser schnell implementiert werden konnte und zudem keine Vorbereitung eines annotierten Trainingsdatensatzes verlangt. Außerdem ist dieser Ansatz schnell und erfordert im Gegensatz zu den anderen vorgestellten Ansätzen wenig Rechenkosten.

#let heading-pipeline = align(center)[#diagram(
  spacing: 8pt,
  cell-size: (10mm, 10mm),
  edge-stroke: 1pt,
  edge-corner-radius: 3pt,
  mark-scale: 60%,
  
  node((0, 0), [Linien], width: 18mm, fill: rgb("#ff89f7").lighten(60%), stroke: 1pt + rgb("#ff89f7").darken(20%), shape: shapes.hexagon.with()),
  edge((0, 0), (2, 0), "-|>"),
  
  node((2, 0), [Filter $[45 degree; 135 degree]$], width: 22mm, fill: rgb("#ffff59").lighten(60%), stroke: 1pt + rgb("#ffff59").darken(20%), corner-radius: 3pt),
  edge((1, 0), (4, 0), "-|>"),
  
  node((4, 0), [Histogramm], width: 22mm, fill: rgb("#5990ff").lighten(60%), stroke: 1pt + rgb("#598bff").darken(20%), corner-radius: 3pt),
  edge((2, 0), (6, 0), "-|>"),
  
  node((6, 0), [Headingwinkel], width: 30mm, fill: rgb("#50dd96").lighten(60%), stroke: 1pt + rgb("#50dd96").darken(20%), shape: shapes.hexagon.with()),
)]

#figure(
  caption: [Pipeline für die Berechnung des Heading-Winkels],
  heading-pipeline
) <pipeline-heading>

== Postprocessing der Ego- und Opplinie
Nachdem das System die Egolinie und die Opplinie erkannt hat, werden diese nachverarbeitet und validiert. Dadurch können Ergebnisse verbessert und Fehldetektionen minimiert werden.

Die folgenden Schritte werden sowohl für eine erkannte Egolinie als auch für eine erkannte Opplinie durchgeführt. Die Parameter der einzelnen Funktionen unterscheiden sich jedoch.

=== Linienpräzisierung
Die Idee, eine erkannte Linie zu präzisieren, basiert darauf, dass Linien je nach Heading der Straße an anderen Stellen zu erwarten sind, als wenn das Fahrzeug geradeaus auf eine Kreuzung zufährt. Außerdem wird ausgenutzt, dass für eine zuverlässige Navigation des Fahrzeugs und ein sicheres Halten vor der Haltelinie die Länge der Linie selbst keine große Relevanz hat. Wichtiger ist die tatsächliche Position. Deswegen wird im ersten Schritt die Linie verlängert. Nun wird die Linie in einem bestimmten Clipbereich abgeschnitten, an der sie bei Anfahrt aus dem aktuellen Winkel zu erwarten ist. Damit wird gewährleistet, dass selbst bei einer Detektion einer Ego- oder Opplinie, die relativ zu der tatsächlichen Lage im Bild falsch positioniert ist, eine Verbesserung der Lokalisierung erreicht werden kann.

Der Clipbereich der Linie ist ein rechteckiger Sektor, der von der oberen Kante der ROI bis zur unteren Kante der ROI reicht. Die Position dieses Clipbereichs entlang der x-Achse ändert sich als Funktion des Headingwinkels. Die Idee ist, dass der Clipbereich der Ego Linie bei Frontalanfahrt an die Kreuzung bei $[0.5 * W_"ROI"; 0.75 * W_"ROI"]$ liegt, wobei $W_"ROI"$ die Breite der Region of Intersest ist. Dort ist die Egolinie zu erwarten, wenn das Fahrzeug frontal auf die Kreuzung zufährt. Die Opplinie liegt bei solch einer Anfahrt im Bereich $[0.15 * W_"ROI"; 0.4 * W_"ROI"]$. Diese Bereiche wurden durch Testing ermittelt.

Dieser Clipbereich wird adaptiv je nach Headingwinkel angepasst. Fährt das Fahrzeug aus einer Kurve an die Kreuzung heran, müssen die Clipbereiche der E- und O-Linie fast übereinander liegen. Ohne adaptive Anpassung würde das Modul die Linien in einer falschen Position vermuten. 

In @ada-clip-o ist qualitativ die Berechnung der neuen Position der rechten und linken Ränder des Clipbereichs für die O-Linie bei einer Linkskurve zu sehen. Es wird auf Basis des Heading ein Faktor zwischen $0$ und $1$ berechnet, welcher dann mit Basiswerten für die Position des linken und rechten Randes des Clipbereichs multipliziert wird, sodass bei vollem Einschlag ein Bereich $[0.05 * W_"ROI"; 0.25 * W_"ROI"]$ berechnet wird. Dies wird analog auch für eine rechte Kurve mit den Maximalwerten $[0.48 * W_"ROI"; 0.7 * W_"ROI"]$ und die Egolinie gemacht. (da werte auch einfügen?)

#code-block(
  caption: [Adaptives Clippen der Haltelinien, hier O-Linie, Qualitativ],
  ```python
angle_factor = (90.0 - angle) / (90.0 - 70.0)
angle_factor = min(1.0, max(0.0, angle_factor))
min_rel = min_rel_base + angle_factor * (0.05 - min_rel_base)
max_rel = max_rel_base + angle_factor * (0.25 - max_rel_base)
 ```,
  highlight-lines: (
  )
) <ada-clip-o>

=== Linienumgebung
Es ist möglich, dass Linien als Ego- und Opplinie erkannt werden, die zu einer Spur oder einer Sperrfläche gehören. Um hierdurch Falschklassifikationen zu vermeiden, wird angenommen, dass tatsächliche Egolinien bei Erweiterung nach links nicht fortlaufend sind. Legt man somit eine _Prüffläche_ mit einem bestimmten Abstand links neben die erkannte Egolinie und prüft, ob die Pixel um diese Prüfllinie hell sind, handelt es sich nicht um eine reale Egolinie. Bei der Opplinie macht man dies zur rechten Seite.

Die Berechnung der Prüflinie geschieht durch Berechnung aller vier neuen Koordinaten der Linie. Der Startpunkt der Prüflinie ($x_s$ und $y_s$) wird mit $x_s = x + d$ und $y_s$ mit $y + m * d$ berechnet. Analog dazu werden die Enden der Prüflinie $x_e$ und $y_e$ nach der selben Formel mit $x_s$ und $y_s$ als Startpunkte berechnet. Als Initialabstand $d$ von der ursprünglichen Linie wird $40$ gewählt. Als Länge der Prüflinie an sich wird ein Wert von $50$ gewählt. Die Weißdichte unter der Linie wird nach der Methode aus @pipeline-lineart berechnet.

=== Linienposition
Ferner wird die Position der Ego- und Opplinie vom Kreuzungszentrum und die Abstände der Linien zueinander (Höhe und Breite) auf Plausibilität geprüft.

== Plausibilierung der Querlinien

== Ergebnisaggregator

= Erläuterungen

Im folgenden werden einige nützliche Elemente und Funktionen zum Erstellen von Typst-Dokumenten mit diesem Template erläutert.

== Ausdrücke und Abkürzungen

Verwende die `gls`-Funktion, um Ausdrücke aus dem Glossar einzufügen, die dann dorthin verlinkt werden. Ein Beispiel dafür ist: 

Im diesem Kapitel wird eine #gls("Softwareschnittstelle") beschrieben. Man spricht in diesem Zusammenhang auch von einem #gls("API"). Die Schnittstelle nutzt Technologien wie das #gls("HTTP").

Das Template nutzt das `glossarium`-Package für solche Glossar-Referenzen. In der zugehörigen #link("https://typst.app/universe/package/glossarium/", "Dokumentation") werden noch weitere Varianten für derartige Querverweise gezeigt. Dort ist auch im Detail erläutert, wie das Glossar aufgebaut werden kann.


== Listen

Es gibt Aufzählungslisten oder nummerierte Listen:

- Dies
- ist eine
- Aufzählungsliste

+ Und
+ hier wird
+ alles nummeriert.

== Abbildungen und Tabellen

Abbildungen und Tabellen (mit entsprechenden Beschriftungen) werden wie folgt erstellt.

=== Abbildungen

#figure(caption: "Eine Abbildung", image(width: 4cm, "assets/ts.svg"))

=== Tabellen

#figure(
  caption: "Eine Tabelle",
  table(
    columns: (1fr, 50%, auto),
    inset: 10pt,
    align: horizon,
    table.header(
      [],
      [*Area*],
      [*Parameters*],
    ),

    text("cylinder.svg"),
    $ pi h (D^2 - d^2) / 4 $,
    [
      $h$: height \
      $D$: outer radius \
      $d$: inner radius
    ],

    text("tetrahedron.svg"), $ sqrt(2) / 12 a^3 $, [$a$: edge length],
  ),
)<table>

== Programm Quellcode

Quellcode mit entsprechender Formatierung wird wie folgt eingefügt:

#figure(
  caption: "Ein Stück Quellcode",
  sourcecode[```ts
    const ReactComponent = () => {
      return (
        <div>
          <h1>Hello World</h1>
        </div>
      );
    };

    export default ReactComponent;
    ```],
)


== Verweise

Für Literaturverweise verwendet man die `cite`-Funktion oder die Kurzschreibweise mit dem \@-Zeichen:
- `#cite(form: "prose", <iso18004>)` ergibt: \ #cite(form: "prose", <iso18004>)
- Mit `@iso18004` erhält man: @iso18004

Tabellen, Abbildungen und andere Elemente können mit einem Label in spitzen Klammern gekennzeichnet werden (die Tabelle oben hat z.B. das Label `<table>`). Sie kann dann mit `@table` referenziert werden. Das ergibt im konkreten Fall: @table

= Fazit

#lorem(50)

#lorem(120)

#lorem(80)