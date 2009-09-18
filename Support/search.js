var foundFiles = 0;
var foundLines = 0;

function f() {
  foundFiles += 1;
  document.getElementById('filecount').innerText = ('' + foundFiles).concat(' file').concat( (foundFiles == 1 ) ? '' : 's' );
}

function l() {
  foundLines += 1;
  document.getElementById('linecount').innerText = ('' + foundLines).concat(' line').concat( (foundLines == 1 ) ? '' : 's' );
}

function searchStarted() {
  document.getElementById('teaser').style.display = 'none';
}

function searchCompleted() {
  document.getElementById('teaser').style.display = 'block';
}

function toggleLines(link, i) {
  var tbody = document.getElementById('file-'+i);
  if (tbody) {
    var showLines = tbody.style.display == 'none';
    tbody.style.display = showLines ? 'table-row-group' : 'none';
    link.innerHTML = showLines ? '-' : '+';
  }
}

var showAllLines = true;

function toggleAllLines(link) {
  showAllLines ^= true;
  var tbodies = document.getElementsByTagName('tbody');
  for (var i = 0; i < tbodies.length; i++) {
    var tbody = tbodies[i];
    if (tbody.className != 'matches') continue;
    tbody.style.display = showAllLines ? 'table-row-group' : 'none';
    tbody.previousSibling.getElementsByTagName('a')[0].innerHTML = showAllLines ? '-' : '+';
  }
  link.innerHTML = (showAllLines ? 'Hide' : 'Show') + ' all matching lines';
}
