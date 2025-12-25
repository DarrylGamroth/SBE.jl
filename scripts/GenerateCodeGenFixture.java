import code.generation.test.*;
import org.agrona.concurrent.UnsafeBuffer;

import java.io.FileOutputStream;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;

public class GenerateCodeGenFixture
{
    public static void main(final String[] args) throws Exception
    {
        final String outputPath = args.length > 0 ? args[0] : "test/java-fixtures/codegen-global-keywords.bin";
        final ByteBuffer byteBuffer = ByteBuffer.allocate(4096);
        final UnsafeBuffer directBuffer = new UnsafeBuffer(byteBuffer);

        final MessageHeaderEncoder messageHeaderEncoder = new MessageHeaderEncoder();
        final GlobalKeywordsEncoder encoder = new GlobalKeywordsEncoder();

        final int length = encode(encoder, directBuffer, messageHeaderEncoder);
        final byte[] bytes = new byte[length];
        byteBuffer.position(0);
        byteBuffer.get(bytes, 0, length);

        try (FileOutputStream out = new FileOutputStream(outputPath))
        {
            out.write(bytes);
        }
    }

    private static int encode(
        final GlobalKeywordsEncoder encoder,
        final UnsafeBuffer directBuffer,
        final MessageHeaderEncoder headerEncoder)
    {
        encoder.wrapAndApplyHeader(directBuffer, 0, headerEncoder)
            .abstract_((byte)1)
            .break_((byte)2)
            .const_((byte)3)
            .continue_((byte)4)
            .do_((byte)5)
            .else_((byte)6)
            .for_((byte)7)
            .if_((byte)8)
            .false_((byte)9)
            .try_((byte)10)
            .struct((byte)11)
            .import_("IMPORT")
            .strictfp_("STRICTFP")
            .new_((byte)12);

        encoder.dataCount(0);

        encoder.go("go-value");
        encoder.package_("package-value");
        encoder.var("var-value");

        final int encodedLength = MessageHeaderEncoder.ENCODED_LENGTH + encoder.encodedLength();
        validateDecode(directBuffer);
        return encodedLength;
    }

    private static void validateDecode(final UnsafeBuffer buffer)
    {
        final MessageHeaderDecoder headerDecoder = new MessageHeaderDecoder();
        final GlobalKeywordsDecoder decoder = new GlobalKeywordsDecoder();

        headerDecoder.wrap(buffer, 0);
        decoder.wrapAndApplyHeader(buffer, 0, headerDecoder);

        if (decoder.abstract_() != 1 || decoder.break_() != 2 || decoder.const_() != 3)
        {
            throw new IllegalStateException("keyword fields mismatch");
        }
        if (decoder.struct() != 11)
        {
            throw new IllegalStateException("struct field mismatch");
        }
        if (!"IMPORT".equals(decoder.import_()) || !"STRICTFP".equals(decoder.strictfp_()))
        {
            throw new IllegalStateException("char array fields mismatch");
        }

        final GlobalKeywordsDecoder.DataDecoder data = decoder.data();
        if (data.count() != 0)
        {
            throw new IllegalStateException("data group mismatch");
        }

        if (!"go-value".equals(decoder.go()) || !"package-value".equals(decoder.package_()) ||
            !"var-value".equals(decoder.var()))
        {
            throw new IllegalStateException("var data mismatch");
        }
    }
}
