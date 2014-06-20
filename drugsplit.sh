awk ' {
if($0 ~ /<*\/drugs\/.+>/ )
print $0 > "drug"
if($0 ~ /<*\/(drug_interactions|references|Enzim)\/.+>/ )
print $0 > "drug_interactions_ref_enzim"
if($0 !~ /<*\/(drugs|drug_interactions|references|Enzim)\/.+>/ )
print $0 > "target"
}' $1

split -nl/2 drug drug_

cat drug_aa > drugbank1
cat drug_interactions_ref_enzim >> drugbank1

cat drug_ab > drugbank2
cat target >> drugbank2
