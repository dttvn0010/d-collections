import gdb.printing

class RCStringPrinter(object):
    def __init__(self, val):
        self.val = val

    def to_string(self):        
        _refCounted = self.val['data']['_refCounted']

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

class RCPrinter(object):
    def __init__(self, val):
        self.val = val

    def children(self):        

        _refCounted = self.val['data']['_refCounted']

        if not _refCounted:
            return get_default_children(self.val)

        _store = _refCounted['_store']
        if not _store:
            return get_default_children(self.val)
        
        _payload = _store['_payload']

        if not _payload:
            return get_default_children(self.val)

        return [('data', _payload), ('size', _payload['_size'])]
        

class RCListDataPrinter(object):
    def __init__(self, val):
        self.val = val

    def children(self):
        items = self.val['_items']
        size = self.val['_size']

        if not items or not size:
            return get_default_children(self.val)

        return [('%d' % i, items[i]) for i in range(size)]

class RCDictDataPrinter(object):
    def __init__(self, val):
        self.val = val

    def children(self):
        table = self.val['_table']
        bucketSize = self.val['_bucketSize']

        if not table or not bucketSize:
            return get_default_children(self.val)

        lst = []
        for i in range(bucketSize):
            ptr = table[i]
            while ptr:                    
                lst.append(('%s' % ptr['key'], ptr['value']))                    
                ptr = ptr['next']
        
        return lst

class RCSetDataPrinter(object):
    def __init__(self, val):
        self.val = val

    def children(self):        
        table = self.val['_table']
        bucketSize = self.val['_bucketSize']

        if not table or not bucketSize:
            return get_default_children(self.val)

        lst = []
        for i in range(bucketSize):
            ptr = table[i]
            while ptr:                    
                lst.append(('%s' % ptr['value'], ''))
                ptr = ptr['next']
        
        return lst

def build_pretty_printer():
    pp = gdb.printing.RegexpCollectionPrettyPrinter("prettybash")    
    pp.add_printer('RCListData', 'RCListData', RCListDataPrinter)    
    pp.add_printer('RCDictData', 'RCDictData', RCDictDataPrinter)    
    pp.add_printer('RCSetData', 'RCSetData', RCSetDataPrinter)    
    pp.add_printer('RCList', 'RCList', RCPrinter)    
    pp.add_printer('RCDict', 'RCDict', RCPrinter)    
    pp.add_printer('RCSet', 'RCSet', RCPrinter)
    pp.add_printer('RCString', 'RCString', RCStringPrinter)
    
    return pp

gdb.printing.register_pretty_printer(
    gdb.current_objfile(),
    build_pretty_printer())

