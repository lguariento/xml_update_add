xquery version "3.1";

module namespace app="http://localhost:8080/exist/apps/app-ct/templates";

import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="http://localhost:8080/exist/apps/app-ct/config" at "config.xqm";
import module namespace tei2="http://exist-db.org/xquery/app/tei2html" at "tei2html.xql";

import module namespace kwic = "http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace functx = 'http://www.functx.com';

declare option exist:serialize "method=html media-type=text/html";

(: From Shakespeare app

declare 
    %templates:wrap
function app:list-letters($node as node(), $model as map(*)) {
    map {
        "letters" :=
            for $letter in collection($config:dataLetters)/tei:TEI
            return
                $letter
    }
};


declare
    %templates:wrap
function app:letter($node as node(), $model as map(*), $id as xs:string?) {
    let $document := collection($config:data_letters)//id($id)
    return
        map { "letter" := $letter }
};

declare function app:header($node as node(), $model as map(*)) {
    tei2:tei2html($model("letter")/tei:teiHeader)
};


:)

declare function functx:substring-after-if-contains
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string? {

   if (contains($arg,$delim))
   then substring-after($arg,$delim)
   else $arg
 } ;
 
declare function functx:name-test
  ( $testname as xs:string? ,
    $names as xs:string* )  as xs:boolean {

$testname = $names
or
$names = '*'
or
functx:substring-after-if-contains($testname,':') =
   (for $name in $names
   return substring-after($name,'*:'))
or
substring-before($testname,':') =
   (for $name in $names[contains(.,':*')]
   return substring-before($name,':*'))
 } ;

declare function functx:remove-attributes
  ( $elements as element()* ,
    $names as xs:string* )  as element() {

   for $element in $elements
   return element
     {node-name($element)}
     {$element/@*[not(functx:name-test(name(),$names))],
      $element/node() }
 } ;

declare function functx:month-name-en
  ( $date as xs:anyAtomicType? )  as xs:string? {

   ('January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December')
   [month-from-date(xs:date($date))]
 } ;

declare function functx:substring-after-last
    ($arg as xs:string? ,
    $delim as xs:string ) as xs:string {
    replace ($arg,concat('^.*',$delim),'')
 };

declare function app:countLetters($node as node(), $model as map(*)) {

    let $count_letters := count(collection(concat($config:app-root, '/data/letters/')))
        return $count_letters

};
 
declare function app:getDocName($node as node()){
    let $name := functx:substring-after-last(document-uri(root($node)), '/')
    return $name
};

declare function app:hrefToDoc($node as node()){
    let $href := concat('show.html','?document=', app:getDocName($node))
        return $href
};

(: The transform (in the http://exist-db.org/xquery/transform function namespace) module 
provides functions for directly applying an XSL stylesheet 
to an XML fragment within an XQuery script.:)

declare function app:XMLtoHTML ($node as node(), $model as map(*)) {
let $ref := xs:string(request:get-parameter("document", ""))
let $xmlPath := concat(xs:string(request:get-parameter("directory", "letters")), '/')
let $xml := doc(replace(concat($config:app-root,"/data/", $xmlPath, $ref), '/exist/', '/db/'))
let $xslPath := concat(xs:string(request:get-parameter("stylesheet", "xmlToHtml")), '.xsl')
let $xsl := doc(replace(concat($config:app-root, "/resources/xslt/", $xslPath), '/exist/', '/db/'))

(: get a list of all the URL parameters that are not either xml= or xslt= :)
let $params :=
<parameters>
   {for $p in request:get-parameter-names()
    let $val := request:get-parameter($p,())
    where not($p = ("document","directory","stylesheet"))
    return
       <param name="{$p}" value="{$val}"/>
   }
</parameters>

return
    transform:transform($xml, $xsl, $params)
};

(:~ : creates a basic table of content derived from the documents stored in '/data/letters' :)
 
declare function app:toc($node as node(), $model as map(*)) {
    for $doc in collection(concat($config:app-root, "/data/letters"))/tei:TEI
    let $id := substring-before(app:getDocName($doc), '.xml')
    let $from := string($doc//tei:correspAction[@type="sent"]/tei:persName)
    let $to := $doc//tei:correspAction[@type="received"]/tei:persName
        let $day := functx:substring-after-last(string(data($doc//tei:correspAction[@type="sent"]/tei:date/@when)), '-')
        let $month := functx:month-name-en(xs:date(data($doc//tei:correspAction[@type="sent"]/tei:date/@when)))
        let $year := substring-before(data($doc//tei:correspAction[@type="sent"]/tei:date/@when), '-')
    let $date := $day || ' ' || $month || ' ' || $year
        return
        
                <tr>
                
                    <th scope="row"><a href="{app:hrefToDoc($doc)}">{$id}</a></th>
                    <td>{$from}</td>
                    <td>{$to}</td>
                    <td>{$date}</td>
                </tr>

};

declare function app:listPers($node as node(), $model as map(*)) {

    let $hitHtml := "hits.html?searchkey="
    for $person in doc(concat($config:app-root, '/data/indices/pedb.xml'))//tei:listPerson/tei:person
    return

    <tr>
    
        <td><a href="{concat($hitHtml,data($person/@xml:id))}">{$person/tei:persName/tei:surname} {$person/tei:persName/tei:forename}</a></td>
    
    </tr>

    
};

declare function app:listpersEdit($node as node(), $model as map(*)) {

    let $hitHtml := "persedit.html?searchkey="

    for $person in doc(concat($config:app-root, '/data/indices/pedb.xml'))//tei:listPerson/tei:person
    order by $person//tei:surname 

    return

    <tr>
    
        <td><a href="{concat($hitHtml,data($person/@xml:id))}">{$person/tei:persName/tei:surname} {$person/tei:persName/tei:forename}</a></td>
    
    </tr>
    
};

declare function app:addPers($node as node(), $model as map(*)) {

    let $peid := doc(concat($config:app-root, '/data/indices/pedb.xml'))//tei:listPerson/tei:person[@xml:id][last()]/@xml:id
    let $idnumber := xs:decimal(substring-after($peid, 'pe'))
    let $newidnumber := (sum($idnumber + 1))
    let $newpeid := concat('pe0', $newidnumber)

    
    return
    
    <div class="container">

<form action="added.html" method="POST">  

    <div class="form-group">
ID:<br/>
<input type="text" name="newpeid" value="{$newpeid}"/>
<br/>
Surname:<br/>
<input type="text" name="surname" placeholder="surname"/>
<br/>
Forename:<br/>
<input type="text" name="forename" placeholder="forename"/>
<br/>
Role name:<br/>
<input type="text" name="rolename" placeholder="role name"/>
<br/>
Additional name:<br/>
<input type="text" name="addname" placeholder="additional name"/>
<br/>
Note:<br/>
<textarea type="text" name="note" placeholder="note" style="height: 300px; width: 95%;"></textarea>

<br/>
<br/>
<input class="btn btn-default" type="submit" value="Submit"/>
<br/>
</div>
</form>
</div>

};

declare function app:listPers_hits($node as node(), $model as map(*), $searchkey as xs:string?)

{

    for $hit in collection(concat($config:app-root, '/data/letters/'))//tei:TEI[.//tei:persName[@ref=$searchkey]]
    let $document := substring-before(app:getDocName($hit), '.xml')
    return
   
    <tr>
        <td><a href="{app:hrefToDoc($hit)}">{$document}</a>
        </td>
    </tr>
};

declare function app:persDetails($node as node(), $model as map(*), $searchkey as xs:string?)

{

    let $note := doc(concat($config:app-root, '/data/indices/pedb.xml'))//tei:listPerson/tei:person[@xml:id=$searchkey]/tei:persName/tei:note
    let $forename := doc(concat($config:app-root, '/data/indices/pedb.xml'))//tei:listPerson/tei:person[@xml:id=$searchkey]/tei:persName/tei:forename
    let $surname := doc(concat($config:app-root, '/data/indices/pedb.xml'))//tei:listPerson/tei:person[@xml:id=$searchkey]/tei:persName/tei:surname
    let $rolename := doc(concat($config:app-root, '/data/indices/pedb.xml'))//tei:listPerson/tei:person[@xml:id=$searchkey]/tei:persName/tei:roleName

    return
    <div>
        <h4>{$rolename} {$forename} {$surname}</h4>
        <p>{$note}</p>
    </div>
};


declare function app:persEdit($node as node(), $model as map(*), $searchkey as xs:string?)

{

    let $on-disk := doc(concat($config:app-root, '/data/indices/pedb.xml'))
    let $peid := doc(concat($config:app-root, '/data/indices/pedb.xml'))//tei:listPerson/tei:person[@xml:id=$searchkey]/@xml:id

    let $surname := doc(concat($config:app-root, '/data/indices/pedb.xml'))//tei:listPerson/tei:person[@xml:id=$searchkey]/tei:persName/tei:surname
    let $oldsurname := $on-disk//tei:listPerson/tei:person[@xml:id=$searchkey]/tei:persName/tei:surname
    let $forename := doc(concat($config:app-root, '/data/indices/pedb.xml'))//tei:listPerson/tei:person[@xml:id=$searchkey]/tei:persName/tei:forename
    let $oldforename := $on-disk//tei:listPerson/tei:person[@xml:id=$searchkey]/tei:persName/tei:forename
    let $rolename := doc(concat($config:app-root, '/data/indices/pedb.xml'))//tei:listPerson/tei:person[@xml:id=$searchkey]/tei:persName/tei:roleName
    let $oldrolename := $on-disk//tei:listPerson/tei:person[@xml:id=$searchkey]/tei:persName/tei:roleName
    let $addname := doc(concat($config:app-root, '/data/indices/pedb.xml'))//tei:listPerson/tei:person[@xml:id=$searchkey]/tei:persName/tei:addName
    let $oldaddname := $on-disk//tei:listPerson/tei:person[@xml:id=$searchkey]/tei:persName/tei:addName
    let $note := doc(concat($config:app-root, '/data/indices/pedb.xml'))//tei:listPerson/tei:person[@xml:id=$searchkey]/tei:persName/tei:note
    let $oldnote := $on-disk//tei:listPerson/tei:person[@xml:id=$searchkey]/tei:persName/tei:note

    return
<div class="container">

<form action="update.html" method="POST">  

    <div class="form-group">
ID:<br/>
<input type="text" name="peid" value="{$peid}"/>
<br/>
Surname:<br/>
<input type="text" name="surname" value="{$surname}"/>
<input type="hidden" name="oldsurname" value="{$oldsurname}"/>
<br/>
Forename:<br/>
<input type="text" name="forename" value="{$forename}"/>
<input type="hidden" name="oldforename" value="{$oldforename}"/>
<br/>
Role name:<br/>
<input type="text" name="rolename" value="{$rolename}"/>
<input type="hidden" name="oldrolename" value="{$oldrolename}"/>
<br/>
Additional name:<br/>
<input type="text" name="addname" value="{$addname}"/>
<input type="hidden" name="oldaddname" value="{$oldaddname}"/>
<br/>
Note:<br/>
<textarea type="text" name="note" style="height: 300px; width: 95%;">{$note/text()}</textarea>
<input type="hidden" name="oldnote" value="{$oldnote}"/>
<br/>
<br/>
<input class="btn btn-default" type="submit" value="Submit"/>
<br/>
</div>
</form>
</div>
};

declare function app:update($node as node(), $model as map(*)) {

let $peid := request:get-parameter('peid', '')

let $surname := request:get-parameter('surname', '')
let $oldsurname := request:get-parameter('oldsurname', '')

let $forename := request:get-parameter('forename', '')
let $oldforename := request:get-parameter('oldforename', '')

let $rolename := request:get-parameter('rolename', '')
let $oldrolename := request:get-parameter('oldrolename', '')

let $addname := request:get-parameter('addname', '')
let $oldaddname := request:get-parameter('oldaddname', '')

let $note := request:get-parameter('note', '')
let $oldnote := request:get-parameter('oldnote', '')

let $on-disk := doc(concat($config:app-root, '/data/indices/pedb.xml'))

let $update := update value $on-disk//tei:person[@xml:id eq $peid]/tei:persName/tei:surname with $surname
let $update := update value $on-disk//tei:person[@xml:id eq $peid]/tei:persName/tei:forename with $forename
let $update := update value $on-disk//tei:person[@xml:id eq $peid]/tei:persName/tei:roleName with $rolename
let $update := update value $on-disk//tei:person[@xml:id eq $peid]/tei:persName/tei:addName with $addname
let $update := update value $on-disk//tei:person[@xml:id eq $peid]/tei:persName/tei:note with $note

return

<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title>Updated</title>
        
    </head>
    <body>
    
         <div class="templates:surround?with=templates/page.html&amp;at=content">
            <h3>Success!</h3>
            <br/>
            <h4>You have changed:</h4>
            <ul>
            
            {if ($oldsurname != $surname) then (<li>surname</li>) else ()}
            {if ($oldforename != $forename) then (<li>forename</li>) else ()}
            {if ($oldrolename != $rolename) then (<li>role name</li>) else ()}
            {if ($oldaddname != $addname) then (<li>additional name</li>) else ()}
            {if ($oldnote != $note) then (<li>note</li>) else ()}
            
            </ul>
            <h4>New data:</h4>
            <p><b>Surname: </b> {if ($surname) then $surname else ("No surname specified!")}</p>
            <p><b>Forename: </b> {if ($forename) then $forename else ("No forename specified!")}</p>
            <p><b>Role name: </b> {if ($rolename) then $rolename else ("No rolename specified!")}</p>
            <p><b>Additional name: </b> {if ($addname) then $addname else ("No additional name specified!")}</p>
            <p><b>Notes: </b> {if ($note) then $note else ("No notes specified!")}</p>
            
            <br/>
            <p><a href="persons.html"><b>Go back to the list</b></a></p>
            <p><a href="persedit.html?searchkey={$peid}"><b>Go back to the record you were editing</b></a></p>

        </div>
        
    </body>
    
</html>

};

declare function app:added($node as node(), $model as map(*)) {

let $newpeid := request:get-parameter('newpeid', '')
let $surname := request:get-parameter('surname', '')
let $forename := request:get-parameter('forename', '')
let $rolename := request:get-parameter('rolename', '')
let $addname := request:get-parameter('addname', '')
let $note := request:get-parameter('note', '')

let $on-disk := doc(concat($config:app-root, '/data/indices/pedb.xml'))

let $newrecord :=

<person xml:id="{xs:ID($newpeid)}" >

<persName xmlns="http://www.tei-c.org/ns/1.0">
<surname>{$surname}</surname>
<forename>{$forename}</forename>
<roleName>{$rolename}</roleName>
<addName>{$addname}</addName>
<note>{$note}</note>
</persName>
</person> 


let $insert := update insert $newrecord following $on-disk//tei:person[@xml:id][last()]

return

<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title>Added {$newpeid}</title>
        
    </head>
    <body>
    
         <div class="templates:surround?with=templates/page.html&amp;at=content">
            <h3>Success!</h3>
            <br/>
            <h4>You have added {$surname} {$forename} ({$newpeid}) to the database!</h4>

            <h4>Details:</h4>

            <p><b>Surname: </b> {$surname}</p>
            <p><b>Forename: </b> {$forename}</p>
            <p><b>Rolename: </b> {$rolename}</p>
            <p><b>Additional name: </b> {$addname}</p>
            <p><b>Notes: </b> {$note}</p>
            <br/>
            <p><a href="persons.html"><b>Go back to the list</b></a></p>
            <p><a href="persedit.html?searchkey={$newpeid}"><b>Revise the details</b></a></p>

        </div>
        
    </body>
    
</html>

};

declare function app:ft_search($node as node(), $model as map(*)) {
    if (request:get-parameter("searchexpr", "") !="") then
    let $searchterm as xs:string:= request:get-parameter("searchexpr", "")
    for $hit in collection(concat($config:app-root, '/data/letters/'))//tei:p[ft:query(.,$searchterm)]
       (: passes the search term to the show.html so that we can highlight the search terms :)
       let $href := concat(app:hrefToDoc($hit), "&amp;searchexpr=", $searchterm)
       let $score as xs:float := ft:score($hit)
       order by $score descending
       return
       <tr>
           <td class="KWIC">{kwic:summarize($hit, <config width="40" link="{$href}" />)}</td>
           <td>{app:getDocName($hit)}</td>
       </tr>
    else
       <div>Nothing to search for</div>
 };
 
 