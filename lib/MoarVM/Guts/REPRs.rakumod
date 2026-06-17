# This is a module for access the guts of MoarVM's REPRs
# Right now lives here because it is incomplete, undocumented and is
# mainly a prof of concept
#
# When grow I'll move it to an independent module.

unit module MoarVM::Guts::REPRs:ver<0.1.12>;
use NativeCall;

constant ptrsize is export = nativesizeof(Pointer);
constant intptr is export = ptrsize == 4 ?? uint32 !! uint64;

constant Offset = do {
    # A type with a trivial REPR
    my Pointer \p = Pointer.new(0xdeadbeaf);  # UNCOVERABLE

    my CArray[intptr] \ar =  # UNCOVERABLE
      nativecast(CArray[intptr], Pointer.new(p.WHERE));

    my int $i;
    repeat { last if ar[$i] == p; } while ++$i < 10;  # UNCOVERABLE

    die "Can't determine actual Offset" if $i == 10;  # UNCOVERABLE
    $i * ptrsize  # UNCOVERABLE
};


# The body of the 'VMArray' REPR
my class MVMArrayB is repr('CStruct') {
    has uint64 $.elems;
    has uint64 $.start;
    has uint64 $.ssize;
    has Pointer $.any;

    method realstart(::?CLASS:D:) {
        +$!start
          ?? Pointer.new(+$!any + +$!start * ptrsize)
          !! $!any
    }
}

# The body of the 'CArray' REPR
my class CArrayB is repr('CStruct') {
    has Pointer $.storage;
    has Pointer[Pointer] $.child;  # UNCOVERABLE
    has int32 $.managed;
    has int32 $.allocated;
    has int32 $.elems;
}

# From Moar v2018.12+ the body of 'CStruct' REPR changed
my class CStructB is repr('CStruct') {
    has Pointer $.cstruct;
    has Pointer[Pointer] $.child_objs;  # UNCOVERABLE
}

my constant %known-bodies = (
    VMArray => MVMArrayB,
    CArray  => CArrayB,
    CStruct => CStructB
);

sub OBJECT_BODY(Mu \any) is export {
    Pointer.new(any.WHERE + Offset);
}

sub BODY_OF(Mu \any) is export {
    my \type = %known-bodies{any.REPR};

    die "Can only handle " ~ %known-bodies.keys if type ~~ Nil;
    nativecast(Pointer[type], OBJECT_BODY(any)).deref;
}

# vim: expandtab shiftwidth=4
