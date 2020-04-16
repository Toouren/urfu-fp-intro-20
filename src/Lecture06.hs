{-# LANGUAGE LambdaCase #-}
module Lecture06 where

{-
  06: Параметрический полиморфизм

  - типизированное лямбда исчисление
  - что такое полиморфизм
  - классифицировать виды полиморфизма
    - interfaces, +, -, классы типов
      - это будет потом
  
  - system f
  - a -> a, a -> [a]
    - higher rank полиморфизм
  - parametricy / free theorems
    - почему это полезно
  - как работают ADTs

  - Func<T, T>
  - generics
    - выразительность
    - ограничения
  
  - разница между parametricity и generics
    - сильные ограничения => сильные гарантии => новая информация 
    - выразительность != мощность (generic'и не менее сильны в плане выразительности,
      но дают меньшие гарантии и поэтому в некотором смысле уступают)
    - tradeoff
-}

{- Типизированное лямбда-исчисление (Simply typed lambda calculus, STLC, λ->)

  В Lecture03 мы познакомились с нетипизированным лямбда-исчислением, научились выражать
  с его помощью арифметику, логику и даже таплы. Вообще, этого уже достаточно, чтобы написать
  всё, что угодно. https://neerc.ifmo.ru/wiki/index.php?title=Тьюринг-полнота.

  Почему бы на этом не остановиться?
  Это всё ещё далеко от того программирования, к которому мы привыкли, и не только
  потому, что это непохоже на C# :), т.е. по форме, но и по содержанию. У этой системы есть проблемы:
  - `false` неотличим от `0`, интерпретация результатов вычислений целиком и полностью лежит
    на их авторе
  - Можно написать бесмысленную программу. Т.е. мы напишем синтаксически корректный терм,
    который даже вычислится до нормальной формы, однако не приведёт нас ни к одному
    из определённых нами значений (нумерал, true/false, пара и т.д.). Например, `plus false true`.
  - Мы можем написать "бесмысленную" программу и случайно, допустив ошибку, но проверка
    синтаксиса (единственная доступная проверка до вычисления) не поможет нам её найти.

  Посмотрим, как можно решить эти проблемы с помощью типов.
  Кажется, что программисту в целом не составит труда, придумать какой-нибудь синтаксис
  и правила навешивания типов, т.к. у нас уже есть интуиция, сформированная кучей языков,
  нужно только эти знания формализовать.

  Синтаксис

    t : T           -- T - тип, t - терм

    t ::=           -- определение терма осталось почти таким же
          x
        | λx:T.t    -- единственное отличие - тип переменной при связывании
        | t t

    T ::=           -- чем может быть тип
          T -> T    -- тип функции
        | Bool      -- нам нужны базовые типы, чтобы появилась хотя бы одна
        | Numeral   -- типизированная переменная
        | ...

    v ::=           -- определим так же те самые "значения"
          true      -- т.е. термы, в которые должны приводить вычисления
        | false
        | 0
        | ...
  
  Нам понадобится понятие контекста.
  Контекст (typing context, также typing environment) — набор предположений
  о типах свободных переменных в терме.

    Γ ::=
          ∅       -- пустой контекст, часто не пишут
        | Γ, x:T  -- формально, оператор «,» расширяет Г,
                  -- добавляя к нему справа новое связывание.

    Символ `⊢`, который используется в правилах вывода, означает "следует", как в логике.
    Например, выражение `⊢ t : T` можно читать как «замкнутый терм t имеет тип T, исходя
    из пустого множества предположений».

    Правила вычисления остаются такими же. Добавим правила типизации.

                 x : T ∈ Г
      (T-Var)   -----------
                 Г ⊢ x : T

                    Г ⊢ t : T' -> T   Г ⊢ t' : T'
      (T-App)   -------------------------------------
                            Г ⊢ t t' : T
      
                  Г, x : T  ⊢  t : T'     -- из контекста следует, что t имеет тип T'2'
      (T-Abs)   -----------------------
                 Г ⊢ λx:T.t : T -> T'

    В качестве примера убедимся, что терм `(λx:Bool.x) true` имеет тип Bool, если Г = x : Bool:

           x:Bool ∈ Г
        ----------------- T-Var        это называется деревом вывода типа
           Г ⊢ x:Bool
    --------------------------- T-Abs    --------------- T-True
    ⊢ λx:Bool.x : Bool -> Bool            ⊢ true : Bool
    ------------------------------------------------------ T-App
                  ⊢ (λx:Bool.x) true : Bool
    
    Обратите внимание, что аннотации типов есть только в определениях связанных
    переменных. В каком смысле этого «достаточно»?

    Теорема (Единственность типов). В любом заданном контексте типизации Г
    терм t, в котором все свободные переменные лежат в области определения Г,
    имеет не более одного типа.
    То есть если терм типизируем (существует T такой, что t : T), то тип у него только один.

    Доказывать мы это, конечно, не будем, но убедиться в этом несложно.
    Действительно, если у терма есть типов, значит можно предъявить соответствующее
    дерево вывода. Ну и сложно придумать, как так это дерево может изменится
    и вывести другой тип при тех же начальных данных.
-}

-- <Задачи для самостоятельного решения>
{-
  Существуют ли такой контекст Γ и такой тип T, что Γ ⊢ x x : T?
  Если да, то приведите пример Γ и T и постройте дерево вывода Γ ⊢ x x : T;
  если нет, то докажите это (напишите, почему)

  *Решение*
-}
-- </Задачи для самостоятельного решения>

{- Что это даёт?

  - Дополнительные проверки синтаксиса.
  Теперь наши ошибки и опечатки с большей вероятностью выявятся в ходе проверок? до запуска,
  возможно продолжительных, вычислений. Снова посмотрим на терм `plus false true`.
  Теперь этот терм нельзя считать корреткной программой. Вы можете убедиться, что он нетипизируем.

  - Безопасность (safety) или корректность (soundness): правильно типизированные термы «не ломаются».
  Вообще, "безопасность языка" расплывчатое понятие. Под ним можно понимать разное.
  Например, мы говорим, что в С++ можно "выстрелить себе в ногу", имея в виду отсутствуие
  безопасности при обращении с памятью, потоками и т.д. Можно сказать, что, говоря "безопасный язык",
  мы имеет в виду, что язык защищает программиста от фатальных ошибок. Но то, что под этим подразумевается
  и как она обеспечивается, сильно зависит от контекста или языка, о котором идёт речь.

  В этом случае безопасность понимается как безопасность системы типов.
  Говорят, что система типов безопасна, если выполненяются два свойства:
  - Продвижение: правильно типизированный терм не может быть тупиковым (не приводить к значению),
    либо это значение, либо он может проделать следующий шаг в соответствии с правилами вычисления.
  - Сохранение: Если правильно типизированный терм проделывает шаг вычисления, то получающийся терм
    также правильно типизирован.
  Мы отделили "правильные" (типизируемые или well-typed) термы от "неправильных", а также
  сделали так, что правильный терм не может превратиться в неправильный при вычислении.

  Эти свойства для STLC можно сформулировать в виде теорем:

  Теорма (Продвижение).
  Пусть t - замкнутый, правильно типизированный терм (т. е. ⊢ t : T для некоторого типа T).
  Тогда либо t является значением, либо имеется терм t′,такой, что t -> t′.

  Для открытых термов теорема неверна: терм `f true` является нормальной формой, но не значением.
  Но это не значит, что с системой что-то не так. Программы, вычисление которых нас интересует
  и есть замкнутые термы.

  Теорема (Сохранение).
  Если Г ⊢ t : T и t -> t′, то Г ⊢ t′ : T.
  
  Другими словами вычисление не меняет тип терма.

  Ещё один важнеший результат — теорема о нормальной форме.
  Теорема
  Если терм типизируем, то он обладает нормальной формой и она достигается при любом порядке редукции.
-}

{- Про "стирание" типов
  Типы помогают проверке программы на корректность, но не нужны при выполнении программы.
  Обычно, языки программирования проверяют типы перед компиляцией, но потом стирают их,
  в скомпилированной программе никаких типов нет.
  Эта идея формализуется с помощью функции "стирания". Её можно определить так:

    erase (x) = x
    erase (λx:T1.t2) = λx.erase (t2)
    erase (t1 t2) = (erase (t1)) (erase (t2))
  
  Можно доказать, что после выполнения такой функции типизированный терм становится
  корректным термом бестипового лямбда-исчисления.

  Функция стирания типа очень проста, гораздо более интересна обратная задача:
  есть нетипизированный терм t, можем ли мы найти типизированный терм такой,
  что при "стирании" получится t? Т.е. можем ли мы вывести тип по терму?
  Мы не будем останавливаться на этом подробно, но дадим некоторое представление
  об этом немного позже.
-}

{- Полиморфизм

  Пропасть между Haskell и лямбда-исчислением уменьшилась, но наша теория всё ещё
  сильно отстаёт. Например, сейчас мы не можем типизировать []. Действительно,
  [] не так уж просты. Они работают, и в `3:[]` и в `'a':[]`. Однако, если мы закрепим
  за ними тип `[Int]` по первому выражению, то это не будет работать во втором выражении.

  А список сейчас мы можем определить только так:

    ListInt = NilInt | ConsInt x ListInt
    ListChar = NilChar | ConsChar x ListChar
    ...

  Что нас, конечно, не устраивает, мы же знаем о принципе DRY.
  Нам нужно уметь использовать один и тот же код для разных типов.
  Кажется, нам нужен полиморфизм. А что вообще такое полиморфизм?

  Часто ответ на этот вопрос зависит от того, в какой парадигме мы находимся,
  в частности, на каком языке пишем. Например, в ООП языках полиморфизмом часто
  называют виртуальные функции, т.е. возможность "подменить" реализацию родительского
  метода в предках.
  Если говорить в общем, то полиморфизм это способность кода работать для разных
  типов. И реализован он может быть по-разному. В этих лекциях мы посмотрим
  по крайней мере на три вида полиморфизма.
  
  Попробуем реализовать полиморфизм в нашей системе.
  Добавим к базовым типам некий тип X, которым будем пользоваться так же, как
  типами Bool или Numeral, но определять не будем:

      T ::=
            X
          | ...
  
  Тогда мы бы могли определить тип [] как [X], где X — переменная типа.
  Допустим у нас есть некий терм t, в типе которого участвует такая переменная X.
  Тогда мы можем задать два существенно различных вопроса о типе t:
  1. «Все ли конкретизации t правильно типизированы?» То есть верно ли, что
  при любом значении X найдётся T такой, что t : T?
  2. «Имеются ли правильно типизированные конкретизации t?» То есть можем ли мы
  найти такой X, что t : T для некоторого T?
  Эти вопросы можно обобщить и на целый набор типовых переменных.

  Например, рассмотрим вот такой терм с двумя типовыми переменными X и Y:

    λf:Y. λa:X. f (f a)
  
  очевидно, что на вопрос 1. ответ — "нет". Действительно при X = Bool, а Y = Char,
  получим нечто невыводимое в нашей системе типов:
      
    λf:Char. λa:Bool. f (f a)
  
  Однако, если заменить Y на X->X, получится правильный типизированный терм:

    λf:X->X. λa:X. f (f a) -- типизируем даже в смысле 1. несмотря на переменную X

  Т.е. на вопрос 2 ответ — "да".

  Следуя по каждому из этих путей, мы получим разные типы полиморфизма.

  Сначала коротко погорим о типе 2.
  Что нужно сделать, чтобы найти типы, при подстановке которых в типовые переменные,
  получится правильно типизированная программа?
  Как мы поняли, что терм `λf:Y. λa:X. f (f a)` нетипизируем в смысле 1?
  Мы увидели апликацию и поняли, что на типе Y есть ограничение Y = T1 -> T2.
  Можно "запомнить" все требования к типовым переменным в виде системы уравнений.
  Тогда проверка типов сводится к решению этой системы.

  Похожим образом работает вывод типов.
  Например, пусть у нас есть апликация `t1 t2`, где Γ ⊢ t1 : T1 и Γ ⊢ t2 : T2,
  выбирем новую типовую переменную X, выпишем ограничение T1 = T2->X и вернём
  X в качестве типа этой апликации.

  Полиморфизм, основанный на этой идее называют let-polymorphism, а также
  ML-style polymorphism, или Damas-Milner polymorphism.

  Первый подход 1 приводит к параметрическому полиморфизму.
-}

{- System F (polymorphic lambda-calculus, second-order lambda calculus)

  Главная идея простая.
  Мы хотим научиться писать универсальные термы, которые будут типизируемыми
  при любых значениях типовых переменных. И, конечно, мы хотим уметь применять
  эти универсальные термы к конкретным типам. Другими словами нам нужно уметь
  делать ровно то, что мы могли делать с переменными в лямбда-исчислении, но
  на уровне типов.

    ΛX.t    -- абстракция типа, где t — терм, а X — переменная типа
    t [T]   -- апликация типа

  Иногда для переменных типа используют маленькую лямбду λX.t

  Рассмотрим в качестве примера применение полиморфной функции id к Int:

    id [Int] = (ΛX. λx:X.x) [Int] = λx:Int.x

  Осталось научиться записывать тип полиморфной функции. Такие функции:
  - зависят от типа, передаваемого в качестве параметра
  - работает с любыми типом.
  Чтобы отразить оба эти свойства тип id записывается как

    id : ∀X.X->X

  Или в общем виде:

                Γ, X  ⊢  t : T          -- Γ, X значит, что мы добавляем в контекст
    (T-TAbs)  ---------------------     -- некоторый тип X
               Γ  ⊢  ΛX.t : ∀X.T      \
                                        -- Типизация
                  Γ  ⊢  t : ∀X.T      /
    (T-TApp)  ---------------------
               Γ  ⊢  t [T'] : [X/T']T   -- [X/T] подстановка для типов


    (E-TApp)  (ΛX.t) [T] -> [X/T]t      -- Вычисление

  Посмотрим, как можно типизировать в System F терм `λx.x x`:

    selfApp : (∀X.X->X) -> (∀X.X->X)
    selfApp = λx:∀X.X->X.x [∀X.X->X] x
                           ^
  Обратите внимание, что здесь мы конкретизировали полиморфную функцию, переданную
  в качестве аргумента ещё одной полиморфной функцией.
-}

-- <Задачи для самостоятельного решения>
{-
  Убедитесь, что selfApp работает. Приведите терм `selfApp id` в нормальную форму
  и запишите все шаги β-редукции ->β.

  selfApp id = ... ->β ...
-}
-- </Задачи для самостоятельного решения>

{- Вернёмся к Haskell

  Обычно, в Haskell пропускается квантор всеобщности, подразумевается, что он
  применяется ко всем типовым переменным полиморфных функций. Но можно включить
  явный forall (вместо ∀) при выводе типов:
 
    > :t []
    [] :: [a]
    >:set -fprint-explicit-foralls
    > :t []
    [] :: forall {a}. [a]

  Можно включить и использование ∀ при объявлении типа, если включить опцию ExplicitForAll:

    > :set -XExplicitForAll
    > :{
    | id :: forall a. a -> a
    | id x = x
    | :}
    > id 4
    4

  С помощью расширения TypeApplications можно включить явное применение
  апликации типа:

    >data List a = Nil | Cons a (List a)
    > l = Nil
    > :t l
    l :: List a
    > b = Nil @Int
    > :t b
    b :: List Int

  Ещё одно интересное расширение позволяет переиспользовать переменные типа,
  в теле функции (включает в себя ExplicitForAll)
  https://wiki.haskell.org/Scoped_type_variables

  myFunc :: forall a.[a] -> [a]     -- явно указываем связывание переменной типа `a`
  myFunc xs = reversedList
      where reversedList :: [a]     -- используем ту же самую `a` внутри функции
          reversedList = reverse xs

  Если скомпилировать этот код без расширения, то компилятор решит, что `a`
  внутри тела — другая переменная типа, никак не связанная с `a` и напечатает
  соответствующую ошибку.
-}

{- Дополнительно

  В этом блоке остались непокрыми ещё по крайней мере две интересные темы.

  Higher rank полиморфизм, Rank-N types
  Все помнят парадокс Рассела (там про брадобрея)? Здесь есть похожая проблема.
  Если под ∀X мы подразумеваем вообще любой X, в том числе полиморфный, то
  в такой системе будут некоторые проблемы, например, в ней нельзя будет вывести
  тип по нетипизированному, но типизируемому терму.
  Но вот если ограничить набор типов, по которым может пробегать X, то система
  работает как надо. X можно ограничить на:
  0 - только неполиморфные, базовые типы, получим rank-0 полиморфизм
  1 - на полиморфные типы, внутри которых переменные могут пробегаться только по
      неполиморфным типам, получим rank-1 полиморфизм
  2 - ...

  Получается матрёшка из вложенных друг в друга типов. В Haskell по умолчанию
  используется rank-1, но можно включить и больше. Подробнее: https://wiki.haskell.org/Rank-N_types

  Rank-N types играют ключевую роль в кодировании пользовательских, т.е. невстроенных
  в язык, ADT. И эта вторая интересная тема. Подробнее: гл. 29 в TAPL (в источниках)
-}

{- О полиморфизмах

    Итак, мы уже столкнулись с двумя типами полиморфизмов. Это всё? Или нет?
    А какие мы уже встречали в других языках? А это те же самые?

    Постараемся ответить на эти вопросы. Какой вообще полиморфизм вы уже встречали?

    Interfaces

    interface ISerializable
    {
      string Serialize();
    }

    class Integer : ISerializable
    {
      int value;

      string Serialize()
      {
        return $"[Integer={value}]";
      }
    }

    class Human : ISerializable
    {
      int age;
      string name;

      string Serialize()
      {
        return $"[Name={name},Age={age}]";
      }
    }

    void Dump(ISerializable object, StreamWriter stream)
    {
      stream.Write(object.Serialize());
    }

    - Гарантируют наличие определённых методов
    - Можно определить собственное поведение в зависимости от типа

    Таком вид полиморфизмы называется Ad hoc полиморфизм. Он есть в Haskell.
    Это тема следующей лекции, stay tuned.


    Шаблоны/Generic/Template
    
    List<T> Reverse<T>(List<T> list)
    {
      ...
    }

    - Можем реализовать один алгоритм для всех типов

    Это очень похоже на такой код на Haskell :

    reverse :: [a] -> [a]
    reverse = ...

    `T` в C# и `a` в Haskell — переменная типа. Можем ли мы сказать, что это
    один и тот же вид полиморфизма?

    Оказывается, нет. Такой полиморфизм в C# — generic полиморфизм,
    он действительно похож на параметрический полиморфизм в System F или Haskell.
    Чем же он отличается?

    Рассмотрим пример вот такой функции на Haskell:

      f :: a -> a           -- или, можно по-дргому
      f :: forall a. a -> a -- или, то же самое в System F
      f : ∀X.X -> X
    
    Что может делать такая функция? Что-нибудь придумали?
    Убедитесь, что то, что вы придумали работает и для строк, и для чисел,
    и для таплов, и для функций. Придумали?
    Это наверняка f(x) = x или id, которая возвращает свой аргумент.

    В ФП часто говорят, что по типу полиморфной функции понятно, что она
    делает. Конечно, так однозначно сказать можно не всегда, Например:

      r : ∀X.[X] -> [X]  -- Подумайте, что может делать такая функция?

    Ну вообще, много чего. Например, возвращать сам список.
    Но, на самом деле, она может только как-то переупорядочить элементы списка
    или взять его подмножество.

    Что же мы можем сказать по аналогичному типу в C#:

      List<T> R<T>(List<T> list)
    
    Наверняка? Ни-че-го. Конечно, можно придерживаться каких-то правил,
    соглашений, паттернов и т.д. Но внутри может быть что-то такое:

      List<T> R<T>(List<T> list)
      {
        ...
        if(a[i] is String str) { ... }
        else if (a[i] is Integer integer) { ... }
        ...
      }
    
    И не только это. Такой полиморфизм не удовлетворяет главному требованию
    параметрического полиморфизма — одинаковая работа для всех типов.
    Он может быть таким, но вы не можете быть в этом уверены наверняка.
    Именно поэтому такой полиморфизм выделяют в отдельный тип.

    Насколько сильны гарантии, которые даёт нам ∀X? У нас есть какое-то
    неопределённое чувство, что `f :: a -> a` в точности равна id, но
    это потому, что мы ничего больше не придумали, или потому, что
    таких больше и правда нет?

    Ответ на этот вопрос (хотя он может быть и неочень понятным после
    первого прочтения) даёт одна из самых известных статей в ФП:

                            Theorems for free!


                              Philip Wadler
                          University of Glasgow

                                June 1989

    В этой статье Wadler берёт основной свойство параметрических функций,
    котороые называется parametricity, и объясняет, как его можно использовать,
    чтобы по типу функций строить теорему, которая выполняется для любой функции
    такого типа:

    "Write down the denition of a polymorphic function on a piece of paper.
    Tell me its type, but be careful not to let me see the function's denition.
    I will tell you a theorem that the function satises."

    Рассмотрим только один пример из этой статьи. Пусть у нас есть функции r и q:

      r : ∀X.[X] -> [X]   
      q : ∀X.∀Y.X -> Y
      
    Тогда `q . map r = r . map q`. -- r слева и справа конкретиризуется для разных типов.
    Интуитивно, мы понимаем, что можно сначала переупорядочить (что-то такое, наверное,
    делает r) элементы списка, а потом отобразить, или сначала отобразить,
    а потом переупорядочить, результат будет один. Но, оказывается, есть теорема,
    которая это доказывает для любых таких функций.

    Итак, мы увидели, что generic полиморфизм не то же самое, что параметрический
    полиморфизм. Второй может давать гарантии, которых нет у первого.
    Значит ли это, что generic полиморфизм хуже?
    Конечно, нет!

    Язык позволяет нам "подкрутить" детали в зависимости от конкретного типа.
    Это довольно удобно. Вы наверняка не раз пользовались конструкциями as, is, typeof.
    В Haskell так нельзя (нужны классы типов, но это не то же самое). 

    На самом деле, в C# вы можете выбрать инструмент под задачу.
    Сделать одно и то же разными способами в зависимости от того, как удобно или хочется.
    Haskell же более строгий, в некотором смысле заставляет вас решать конкретную задачу
    конкретным способом. Взамен мы получаем гарантии.

    Здесь в силу вступает привычный tradeoff между удобством и строгостью.
    Почему все так плохо относятся к php или JavaScript? Ведь, на самом деле,
    на обоих языках можно писать хороший код. Проблема в том, что на них легче
    писать плохой код, рано или поздно этим кто-нибудь воспользуется.

    [раздув со статической и динамической типизацией, вы ведь в таком участвовали?]
-}

-- <Задачи для самостоятельного решения>
{-
  Придумайте, что могут делать перечисленные ниже функции, и реализуйте их.
  При этом старайтесь не ограничиваться тривиальными ответами и ищите
  функции, в которых действительно есть смысл. Можно пользоваться стандартными
  функциями.

  Например, `r :: [a] -> [a]` можно определить как `r = id @Int`,
  но зачем тогда её объявлять, когда можно воспользоваться id?
-}

f :: [a] -> Int
f = length

g :: (a -> b)->[a]->[b]
g = map

q :: a -> a -> a
q x y = x

p :: (a -> b) -> (b -> c) -> (a -> c)
p f g = g . f

{-
  Крестики-нолики Чёрча.

  Вам нужно написать игру крестики-нолики, используя только функции.
  Для запуска игры из GHCI загрузите модуль Lecture06XsOs и вызовите функцию startXsOs:

    > :load src/Lecture06/XsOs.hs
    > startXsOs
  
  Но для её запуска нужно хоть как-нибудь реализовать функции ниже.
-}

data Index = First | Second | Third deriving Eq
data Value = Zero | Cross | Empty deriving Eq
type Row = Index -> Value
type Field = Index -> Row

-- Обсудим это на следующем занятии
instance Show Index where
  show First = "1"
  show Second = "2"
  show Third = "3"

instance Show Value where
  show Zero = "o"
  show Cross = "x"
  show Empty = "."

createRow :: Value -> Value -> Value -> Row
createRow x y z = \case
  First -> x
  Second -> y
  Third -> z

createField :: Row -> Row -> Row -> Field
createField x y z = \case
  First -> x
  Second -> y
  Third -> z

-- Чтобы было с чего начинать проверять ваши функции
emptyField :: Field
emptyField = createField emptyLine emptyLine emptyLine
  where
    emptyLine = createRow Empty Empty Empty

setCellInRow :: Row -> Index -> Value -> Row
setCellInRow r i v = \ind -> if ind == i then v else r ind

-- Возвращает новое игровое поле, если клетку можно занять.
-- Возвращает ошибку, если место занято.
setCell :: Field -> Index -> Index -> Value -> Either String Field
setCell field i j v = 
  if field i j == Empty
    then Right newField
    else Left error
    where
      error = "There is '" ++ show (field i j) ++ "' on " ++ show i ++ " " ++ show j
      newField = \this -> if i == this then setCellInRow (field i) j v else field this

data GameState = InProgress | Draw | XsWon | OsWon deriving (Eq, Show)

getGameState :: Field -> GameState
getGameState field
  | win Zero = OsWon
  | win Cross = XsWon
  | empty = InProgress
  | otherwise = Draw
  where
    indexes = [First, Second, Third]
    fullEqual p xs = all (== p) xs

    isHorEqual r p = fullEqual p (map (\x -> field r x) indexes)
    isVertEqual c p = fullEqual p (map (\x -> field x c) indexes)
    isDiagonalEqual p = fullEqual p (map (\x -> field x x) indexes) || fullEqual p [field First Third, field Second Second, field Third First]
    win p = isDiagonalEqual p || any (\x -> x == True) (map (\x -> (isHorEqual x p || isVertEqual x p)) indexes)

    allCells = map (\r -> map (\c -> (field r c)) indexes) indexes

    empty = any(Empty==) (allCells >>= id)
-- </Задачи для самостоятельного решения>

{- Источники

- [TAPL] Types and Programming Languages. Benjamin C. Pierce
- Theorems for free! Philip Wadler http://ecee.colorado.edu/ecen5533/fall11/reading/free.pdf
- Why Functional Programming Matters. John Hughes https://www.cs.kent.ac.uk/people/staff/dat/miranda/whyfp90.pdf
- https://bartoszmilewski.com/2014/09/22/parametricity-money-for-nothing-and-theorems-for-free/
-}
