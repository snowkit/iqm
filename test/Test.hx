
import iqm.IQM;

class Test {
    
    static function main() {
            
        var name = 'mrfixit.iqm';
        var iqm = IQM.parse(haxe.Resource.getBytes(name));

        trace('Testing $name:\n');

        if(iqm != null) {
            IQM.dump(iqm);
        } else {
            trace('Failed to parse file: $name');
        }
    
    } //main

} //Test