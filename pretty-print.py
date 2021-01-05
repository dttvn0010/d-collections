import gdb.printing

MAX_ITEMS = 10000

class RCStringPrinter(object):
    def __init__(self, val):
        self.val = val

    def to_string(self):        
        _refCounted = self.val['_data']['_refCounted']

        if not _refCounted:
            return "Undefined"

        _store = _refCounted['_store']
        if not _store:
            return "Undefined"
        
        _payload = _store['_payload']
        if not _payload:
            return "Undefined"

        return _payload['_ptr']
    
def get_default_children(val):
    return [(key, val[key]) for key in val.type.iterkeys()]

class RCListPrinter(object):
    def __init__(self, val):
        self.val = val
    
    def to_string(self): 
        return ""

    def children(self):        

        _refCounted = self.val['_data']['_refCounted']

        if not _refCounted:
            return get_default_children(self.val)

        _store = _refCounted['_store']
        if not _store:
            return get_default_children(self.val)
        
        _payload = _store['_payload']

        if not _payload:
            return get_default_children(self.val)

        items = _payload['_items']
        size = _payload['_size']

        if not items or not size:
            return get_default_children(self.val)

        if size < 0:
            return []

        return [('%d' % i, items[i]) for i in range(min(MAX_ITEMS,size))]

class RCDictPrinter(object):
    def __init__(self, val):
        self.val = val

    def to_string(self): 
        return ""

    def children(self):
        _refCounted = self.val['_data']['_refCounted']

        if not _refCounted:
            return get_default_children(self.val)

        _store = _refCounted['_store']
        if not _store:
            return get_default_children(self.val)
        
        _payload = _store['_payload']

        if not _payload:
            return get_default_children(self.val)

        table = _payload['_table']
        bucketSize = _payload['_bucketSize']

        if not table or not bucketSize:
            return get_default_children(self.val)

        lst = []
        for i in range(bucketSize):
            ptr = table[i]
            while ptr:                    
                lst.append(('%s' % ptr['key'], ptr['value']))                    
                ptr = ptr['next']
                if len(lst) > MAX_ITEMS: break
            
            if len(lst) > MAX_ITEMS: break

        return lst
        
class RCSetPrinter(object):
    def __init__(self, val):
        self.val = val

    def to_string(self): 
        return ""

    def children(self):
        _dict = self.val['_dict']
        if not _dict:
            return get_default_children(self.val)

        _refCounted = _dict['_data']['_refCounted']

        if not _refCounted:
            return get_default_children(self.val)

        _store = _refCounted['_store']
        if not _store:
            return get_default_children(self.val)
        
        _payload = _store['_payload']

        if not _payload:
            return get_default_children(self.val)

        table = _payload['_table']
        bucketSize = _payload['_bucketSize']

        if not table or not bucketSize:
            return get_default_children(self.val)

        lst = []
        for i in range(bucketSize):
            ptr = table[i]
            while ptr:                    
                lst.append(('%s' % ptr['key'], ptr['value']))                    
                ptr = ptr['next']
                if len(lst) > MAX_ITEMS: break

            if len(lst) > MAX_ITEMS: break
            
        return lst

def build_pretty_printer():
    pp = gdb.printing.RegexpCollectionPrettyPrinter("prettybash")    
    pp.add_printer('RCList', '^RC.List!', RCListPrinter)    
    pp.add_printer('RCDict', '^RC.Dict!', RCDictPrinter)    
    pp.add_printer('RCSet', '^RC.Set!', RCSetPrinter)
    pp.add_printer('RCString', '^RC.String', RCStringPrinter)
    
    return pp

gdb.printing.register_pretty_printer(
    gdb.current_objfile(),
    build_pretty_printer())

